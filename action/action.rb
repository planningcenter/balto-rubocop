#!/usr/bin/env ruby

# frozen_string_literal: true

require "json"
require "ostruct"

require_relative "./action_utils"
require_relative "./git_utils"
require_relative "./check_run"

if ENV["BALTO_LOCAL_TEST"]
  require_relative "./fake_check_run"
end

CHECK_NAME = "RuboCop"

event = JSON.parse(
  File.read(ENV["GITHUB_EVENT_PATH"]),
  object_class: OpenStruct
)

check_run_class = ENV["BALTO_LOCAL_TEST"] ? FakeCheckRun : CheckRun

check_run = check_run_class.new(
  name: CHECK_NAME,
  owner: event.repository.owner.login,
  repo: event.repository.name,
  token: ENV["GITHUB_TOKEN"],
)

check_run_create = check_run.create(event: event)

if !check_run_create.ok?
  raise "Couldn't create check run #{check_run_create.inspect}"
end

RUBOCOP_TO_GITHUB_SEVERITY = {
  "refactor" => "warning",
  "convention" => "warning",
  "warning" => "warning",
  "error" => "failure",
  "fatal" => "failure"
}.freeze

FAILURE_LEVEL_ANNOTATIONS = RUBOCOP_TO_GITHUB_SEVERITY.select { |_, v| v == "failure" }.keys

def git_root
  @git_root ||= Pathname.new(GitUtils.root)
end

def working_dir
  @working_dir ||= Pathname.new(Dir.getwd)
end

def file_fullpath(relative_path)
  if git_root != working_dir
    File.join(working_dir.relative_path_from(git_root), relative_path)
  else
    relative_path
  end
end

def generate_annotations(compare_sha:)
  annotations = []

  rubocop_json =
    `git diff --name-only #{compare_sha} --diff-filter AM --relative | xargs bundle exec rubocop --force-exclusion --format json`

  rubocop_output = JSON.parse(rubocop_json, object_class: OpenStruct)

  rubocop_output.files.each do |file|
    path = file_fullpath(file.path)

    change_ranges = GitUtils.generate_change_ranges(path, compare_sha: compare_sha)

    file.offenses.each do |offense|
      next unless report_offense?(offense, change_ranges: change_ranges)

      annotations.push(
        path: path,
        start_line: offense.location.start_line,
        end_line: offense.location.last_line,
        annotation_level: RUBOCOP_TO_GITHUB_SEVERITY[offense.severity],
        message: offense.message
      )
    end
  end

  annotations
end

def report_offense?(offense, change_ranges:)
  FAILURE_LEVEL_ANNOTATIONS.include?(offense.severity) ||
    change_ranges.any? { |range| range.include?(offense.location.start_line) }
end

begin
  previous_sha = if event.pull_request.nil?
                   event.before
                 else
                   event.pull_request.base.sha
                 end
  annotations = generate_annotations(compare_sha: previous_sha)
rescue Exception => e
  puts e.message
  puts e.backtrace.inspect
  resp = check_run.error(message: e.message)
  p resp
  p resp.json
else
  check_run.update(annotations: annotations)
  ActionUtils.set_output("issuesCount", annotations.count)
end

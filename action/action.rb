# frozen_string_literal: true

require "json"
  require "ostruct"

require_relative "./install_gems"
require_relative "./git_utils"
require_relative "./check_run"

CHECK_NAME = "Rubocop"

event = JSON.parse(
  File.read(ENV["GITHUB_EVENT_PATH"]),
  object_class: OpenStruct
)

check_run = CheckRun.new(
  name: CHECK_NAME,
  owner: event.repository.owner.login,
  repo: event.repository.name,
  token: ENV["GITHUB_TOKEN"],
)

check_run_create = check_run.create(event: event)

if !check_run_create.ok?
  raise "Couldn't create check run #{resp.inspect}"
end

compare_sha = event.pull_request.base.sha

rubocop_json = Bundler.with_original_env do
  `git diff --name-only #{compare_sha} --diff-filter AM --relative | xargs rubocop --force-exclusion --format json`
end

rubocop_output = JSON.parse(rubocop_json, object_class: OpenStruct)

RUBOCOP_TO_GITHUB_SEVERITY = {
  "refactor" => "failure",
  "convention" => "failure",
  "warning" => "warning",
  "error" => "failure",
  "fatal" => "failure"
}.freeze

annotations = []

rubocop_output.files.each do |file|
  change_ranges = GitUtils.generate_change_ranges(file.path, compare_sha: compare_sha)

  file.offenses.each do |offense|
    next unless change_ranges.any? { |range| range.include?(offense.location.start_line) }

    annotations.push(
      path: file.path,
      start_line: offense.location.start_line,
      end_line: offense.location.last_line,
      annotation_level: RUBOCOP_TO_GITHUB_SEVERITY[offense.severity],
      message: offense.message
    )
  end
end

resp = check_run.update(annotations: annotations)

p resp
p resp.json

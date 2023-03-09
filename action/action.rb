#!/usr/bin/env ruby

# frozen_string_literal: true

require "json"
require "ostruct"

require_relative "./action_utils"
require_relative "./git_utils"

RUBOCOP_TO_GITHUB_SEVERITY = {
  "refactor" => "warning",
  "convention" => "warning",
  "warning" => "warning",
  "error" => "error",
  "fatal" => "error"
}.freeze

FAILURE_LEVEL_ANNOTATIONS = RUBOCOP_TO_GITHUB_SEVERITY.select { |_, v| v == "error" }.keys

CONCLUSION_LEVEL_TO_EXIT_CODE = Hash.new(0).merge({
  # When Github finally (re)adds support for setting workflow status to neutral,
  # we should change this.
  "neutral" => 0,
  "failure" => 1,
  "action_required" => 1,
})

event = JSON.parse(
  File.read(ENV["GITHUB_EVENT_PATH"]),
  object_class: OpenStruct
)

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

      annotation = Annotation.new(
        path: path,
        start_line: offense.location.start_line,
        end_line: offense.location.last_line,
        annotation_level: RUBOCOP_TO_GITHUB_SEVERITY[offense.severity],
        message: offense.message
      )
      annotations.push annotation
    end
  end

  annotations
end

def maybe_exit_with_failure(number_of_annotations)
  exit_code = CONCLUSION_LEVEL_TO_EXIT_CODE[ENV["INPUT_CONCLUSIONLEVEL"]]
  if number_of_annotations > 0 && exit_code > 0
    abort "Failing because #{number_of_annotations} annotation(s) found & conclusionLevel is set to #{ENV["INPUT_CONCLUSIONLEVEL"]}"
  end
end

Annotation = Struct.new(:path, :start_line, :end_line, :annotation_level, :message, keyword_init: true) do
  def to_output_command
    args = []
    args << "file=#{path}" if path
    args << "line=#{start_line}" if start_line
    args << "endLine=#{end_line}" if end_line
    "::#{annotation_level} #{args.join(',')}::#{message}"
  end
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
  ActionUtils.debug "Using this as previous sha: #{previous_sha}"
  annotations = []
  if previous_sha.chars.uniq == ["0"]
    error_msg = "#{previous_sha} is not a sha we can compare to -- aborting action run."
    # Make sure this gets logged
    puts error_msg
    # ...because this output might not be captured
    abort error_msg
  else
    annotations = generate_annotations(compare_sha: previous_sha)
  end
rescue Exception => e
  puts e.message
  puts e.backtrace.inspect
  abort("::error:: #{e.message}")
else
  ActionUtils.set_output("issuesCount", annotations.count)
  annotations.each do |note|
    puts note.to_output_command
  end
  maybe_exit_with_failure(annotations.count)
end

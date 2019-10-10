# frozen_string_literal: true

require "json"
require "ostruct"
require "net/http"
require "time"

require_relative "./git_utils"

CHECK_NAME = "Balto - Rubocop"

HEADERS = {
  "Content-Type": "application/json",
  "Accept": "application/vnd.github.antiope-preview+json",
  "Authorization": "Bearer #{ENV['GITHUB_TOKEN']}",
  "User-Agent": "rubocop-action"
}.freeze

event = JSON.parse(
  File.read(ENV["GITHUB_EVENT_PATH"]),
  object_class: OpenStruct
)

compare_sha = event.pull_request.base.sha

Dir.chdir(ENV["GITHUB_WORKSPACE"])
rubocop_json = `git diff --name-only #{compare_sha} --diff-filter AM | xargs rubocop --format json`

# print json

rubocop_output = JSON.parse(rubocop_json, object_class: OpenStruct)

RUBOCOP_TO_GITHUB_SEVERITY = {
  "refactor" => "failure",
  "convention" => "failure",
  "warning" => "warning",
  "error" => "failure",
  "fatal" => "failure"
}.freeze

annotations = []
offense_count = 0

rubocop_output.files.each do |file|
  change_ranges = GitUtils.generate_change_ranges(file.path, compare_sha: compare_sha)

  file.offenses.each do |offense|
    next unless change_ranges.any? { |range| range.include?(offense.location.start_line) }

    offense_count += 1

    annotations.push(
      path: file.path,
      start_line: offense.location.start_line,
      end_line: offense.location.last_line,
      annotation_level: RUBOCOP_TO_GITHUB_SEVERITY[offense.severity],
      message: offense.message
    )
  end
end

conclusion = if offense_count.zero?
               "success"
             else
               "failure"
             end

output = {
  title: CHECK_NAME,
  summary: "#{offense_count} offense(s) found",
  annotations: annotations
}

p output

body = {
  name: CHECK_NAME,
  head_sha: event.pull_request.head.sha,
  status: "completed",
  completed_at: Time.now.iso8601,
  conclusion: conclusion,
  output: output
}

http = Net::HTTP.new("api.github.com", 443)
http.use_ssl = true
path = "/repos/#{event.repository.owner.login}/#{event.repository.name}/check-runs"

resp = http.post(path, body.to_json, HEADERS)

p resp
p resp.body

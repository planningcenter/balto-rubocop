require "time"
require "net/http"
require "json"
require "ostruct"

class CheckRun
  def initialize(name:, owner:, repo:, token:)
    @name = name
    @owner = owner
    @repo = repo

    @headers = {
      "Content-Type": "application/json",
      "Accept": "application/vnd.github.antiope-preview+json",
      "Authorization": "Bearer #{token}",
      "User-Agent": "rubocop-action"
    }.freeze
  end

  def create(event:)
    body = {
      name: name,
      head_sha: ENV['GITHUB_SHA'],
      status: "in_progress",
      started_at: Time.now.iso8601,
    }

    post("/repos/#{owner}/#{repo}/check-runs", body).tap do |response|
      if response.ok?
        @id = response.json.id
      end
    end
  end

  def update(annotations:)
    conclusion = if annotations.length.zero?
                   "success"
                 else
                   ENV["INPUT_CONCLUSIONLEVEL"]
                 end

    output = {
      title: name,
      summary: "#{annotations.length} offense(s) found",
      annotations: annotations
    }

    body = {
      status: "completed",
      completed_at: Time.now.iso8601,
      conclusion: conclusion,
      output: output,
    }

    patch("/repos/#{owner}/#{repo}/check-runs/#{id}", body)
  end

  def error(message:)
    output = {
      title: name,
      summary: "Error during linting process",
      text: message
    }

    body = {
      status: "completed",
      completed_at: Time.now.iso8601,
      conclusion: "failure",
      output: output,
    }

    patch("/repos/#{owner}/#{repo}/check-runs/#{id}", body)
  end

  private

  attr_reader :owner, :repo, :headers, :id, :name

  def post(path, body)
    GithubAPIResponse.new(http.post(path, body.to_json, headers))
  end

  def patch(path, body)
    GithubAPIResponse.new(http.patch(path, body.to_json, headers))
  end

  def http
    @http ||= begin
      http = Net::HTTP.new("api.github.com", 443)
      http.use_ssl = true
      http
    end
  end
end

class GithubAPIResponse
  def initialize(http_response)
    @http_response = http_response
  end

  def ok?
    status >= 200 && status < 300
  end

  def json
    @json ||= JSON.parse(body, object_class: OpenStruct)
  end

  def body
    http_response.body
  end

  def inspect
    http_response.inspect
  end

  def status
    @status ||= http_response.code.to_i
  end

  private

  attr_reader :http_response
end

require 'time'
require 'net/http'
require 'json'
require 'ostruct'

class OutputCheckRun
  CONCLUSION_TO_EXIT_CODE = {
    success: 0,
    failure: 1,
    neutral: 78
  }

  def initialize(*); end

  def create(event:); end

  # path: path,
  # start_line: offense.location.start_line,
  # end_line: offense.location.last_line,
  # annotation_level: RUBOCOP_TO_GITHUB_SEVERITY[offense.severity],
  # message: offense.message
  def update(annotations:)
    conclusion = if annotations.length.zero?
                   'success'
                 elsif annotations.any? { |a| a[:annotation_level] == 'error' }
                   'failure'
                 else
                   ENV['INPUT_CONCLUSIONLEVEL']
                 end

    # output = {
    #   title: name,
    #   summary: "#{annotations.length} offense(s) found",
    #   annotations: annotations
    # }

    # body = {
    #   status: "completed",
    #   completed_at: Time.now.iso8601,
    #   conclusion: conclusion,
    #   output: output,
    # }

    # ::error file={name},line={line},endLine={endLine},title={title}::{message}

    # patch("/repos/#{owner}/#{repo}/check-runs/#{id}", body)
    annotations.each do |n|
      args = []
      args << "file=#{n.path}" if n.path
      args << "line=#{n.start_line}" if n.start_line
      args << "endLine=#{n.end_line}" if n.end_line
      puts "::#{n.annotation_level} #{args.join(',')}::#{message}"
    end

    exit CONCLUSION_TO_EXIT_CODE[conclusion]
  end

  def error(message:)
    puts "::errror::#{message}"
  end
end

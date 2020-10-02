require "ostruct"

class FakeCheckRun
  def initialize(name:, owner:, repo:, token:)
    @name = name
    @owner = owner
    @repo = repo

    puts "FAKE CHECK RUN: initialized with \n"
    puts({ name: name, owner: owner, repo: repo }.to_yaml)
  end

  def create(event:)
    puts "FAKE CHECK RUN: created with \n"
    puts event.to_yaml

    OpenStruct.new(ok?: true)
  end

  def update(annotations:)
    puts "FAKE CHECK RUN: received annotations \n"
    puts annotations.to_yaml
    OpenStruct.new(json: annotations.to_json)
  end

  def error(message:)
    puts "FAKE CHECK RUN: received error message \n"
    puts message.to_yaml
    OpenStruct.new(json: message.to_json)
  end
end

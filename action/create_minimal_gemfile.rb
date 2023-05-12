require "bundler"

require_relative "./action_utils"

class MinimalGemfile
  def initialize(lockfile)
    @lockfile = lockfile
  end

  def contents
    specs = gem_specifications

    ActionUtils.debug "Found these gems"
    ActionUtils.debug specs.map { |s| [s.name, s.version.to_s] }.inspect

    <<~RUBY
    source "https://rubygems.org"

    #{gem_specifications_to_lines(specs).join("\n")}
    RUBY
  end

  private

  def gem_specifications_to_lines(specs)
    specs.map do |spec|
      options =
        source_options(spec.source).map { |(k, v)| %(, #{k}: "#{v}") }.join
      %(gem "#{spec.name}", "#{spec.version}"#{options})
    end
  end

  def source_options(source)
    case source
    when Bundler::Source::Git
      {
        git: source.options.fetch("uri"),
        ref: source.options.fetch("revision")
      }
    when Bundler::Source::Rubygems
      if source.remotes.size > 1
        fail "uncharted territory: gem source with multiple remotes #{source.remotes.inspect}"
      end

      if source.remotes.one? &&
           source.remotes.first.to_s !~ %r{https://rubygems.org}
        { source: source.remotes.first.to_s }
      else
        {}
      end
    when Bundler::Source::Path
      { path: source.path }
    else
      fail "unknown gem source type: #{source.class}"
    end
  end

  def gem_specifications
    Bundler::LockfileParser
      .new(Bundler.read_file(@lockfile))
      .specs
      .select { |s| gem_we_care_about?(s.name) }
  end

  def gem_we_care_about?(name)
    additional_gems = ENV["INPUT_ADDITIONALGEMS"].to_s.split(",")
    additional_gems.include?(name) || name&.start_with?("rubocop")
  end
end

if File.exist?("Gemfile.lock")
  puts "Found Gemfile.lock!"
elsif File.exist?("Gemfile")
  puts "Found Gemfile! Using that to create a Gemfile.lock"
  `bundle lock`
  puts "Using new Gemfile.lock"
else
  raise "Assumed a Gemfile.lock or a Gemfile file existed... but it doesn't!"
end

balto_gemfile = "balto-rubocop.gemfile"
puts "Writing #{balto_gemfile}"
contents = MinimalGemfile.new("Gemfile.lock").contents
ActionUtils.debug("#{balto_gemfile} contents:")
contents.each_line { |l| ActionUtils.debug(l) }
File.write(balto_gemfile, contents)

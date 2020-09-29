class GemfileStrategy
  def install
    require "bundler/inline"

    specs = gem_specifications

    puts "Found these gems"
    puts specs.inspect

    gemfile(true) do
      source "https://rubygems.org"

      specs.each do |(name, version)|
        gem name, version
      end
    end
  end

  private

  def gem_specifications
    File
      .read('Gemfile.lock')
      .lines
      .select { |l| line_contains_gem_we_care_about?(l) }
      .select { |l| line_contains_exact_version?(l) }
      .map { |l| gemfile_line_to_specification(l) }
  end

  def gemfile_line_to_specification(line)
    name, version = line.split(' ')
    version = version.tr('()', '')
    [name, version]
  end

  def line_contains_gem_we_care_about?(line)
    name = line.strip.split(' ').first
    gem_we_care_about?(name)
  end

  def line_contains_exact_version?(line)
    line.match(/\(\d*\.\d*\.\d*\)/)
  end
end

class GemspecStrategy
  attr_reader :gemspec

  def initialize(filename)
    @gemspec = Gem::Specification.load(filename)
  end

  def install
    gemspec
      .dependencies
      .select { |d| gem_we_care_about?(d.name) }
      .each { |d| Gem.install(d.name, d.requirement) }
  end
end

def gem_we_care_about?(name)
  name == 'standard' || name&.start_with?('rubocop')
end

def choose_gem_strategy
  if File.exist?('Gemfile.lock')
    GemfileStrategy.new
  elsif gemspec_file = Dir.glob('*.gemspec').first
    GemspecStrategy.new(gemspec_file)
  else
    raise "Assumed a Gemfile.lock or a .gemspec file existed... but it doesn't!"
  end
end

choose_gem_strategy.install

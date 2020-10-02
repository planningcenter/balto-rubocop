module GitUtils
  module_function

  def generate_change_ranges(path, compare_sha:)
    Dir.chdir(root) do
      udf_lines = `git diff -U0 --no-color #{compare_sha} -- #{path}`
        .lines
        .grep(/^@@.+\+\d/)

      udf_lines
        .map { |l| l.match(/\+(?<range_start>\d+)(?:,(?<range_length>\d*))?/) }
        .compact
        .map do |md|
          range_start = md["range_start"].to_i
          range_length = md["range_length"] ? md["range_length"].to_i - 1 : 0

          range_start..(range_start + range_length)
        end
    end
  end

  def root
    `git rev-parse --show-toplevel`.strip
  end
end

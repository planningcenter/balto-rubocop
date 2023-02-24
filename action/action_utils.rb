module ActionUtils
  module_function

  def set_output(key, value)
    `echo "#{key}=#{value}" >> $GITHUB_OUTPUT`
  end

  def debug(message)
    puts "::debug::#{message}"
  end
end

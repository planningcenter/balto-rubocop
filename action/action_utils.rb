module ActionUtils
  module_function

  def set_output(key, value)
    puts "::set-output name=#{key}::#{value}"
  end
end

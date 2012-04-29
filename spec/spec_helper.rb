require 'deject'

catch_stderr = Module.new do
  require 'stringio'

  def catch_stderr
    old_stderr = $stderr
    $stderr = StringIO.new
    yield
  ensure
    to_return = $stderr.string
    $stderr = old_stderr
    return to_return
  end
end

RSpec.configure do |config|
  config.include catch_stderr
end

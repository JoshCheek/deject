deject = begin
  Deject
rescue NameError
  Deject = Class.new
end

deject.module_eval do
  VERSION = "0.0.1"
end

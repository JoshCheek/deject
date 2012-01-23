require "deject/version"

lib_switch = ENV['deject_as_function'] ? 'functional' : 'object_oriented'
require "deject/#{lib_switch}"

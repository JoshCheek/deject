case ENV['deject_implementation']
when 'object_oriented'
  require 'deject/object_oriented'
else
  require 'deject/functional'
end

require "deject/version"

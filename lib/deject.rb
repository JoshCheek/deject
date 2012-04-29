require "deject/version"

module Deject
  UninitializedDependency = Class.new StandardError
end

# Not a common way of writing code in Ruby, I know.
# But I tried out several implementations and found this was the easiest to
# work with within the constraints of the gem (that it doesn't leave traces
# of itself all over your objects)
def Deject(klass)
  uninitialized_error = lambda do |meth|
    raise Deject::UninitializedDependency, "#{meth} invoked before being defined"
  end

  define_instance_methods = lambda do |meth, default_block|
    # define the getter
    define_method meth do
      uninitialized_error[meth] unless default_block
      value = default_block.call self
      define_singleton_method(meth) { value }
      send meth
    end

    # define the override
    define_method :"with_#{meth}" do |value=nil, &block|

      # redefine getter if given a block
      if block
        define_singleton_method meth do
          value = block.call self
          define_singleton_method(meth) { value }
          send meth
        end

      # always return value if given a value
      else
        define_singleton_method(meth) { value }
      end

      self
    end
    self
  end

  has_dependency = lambda do |meth|
    instance_methods.include?(meth.intern) && instance_methods.include?(:"with_#{meth}")
  end


  # define klass.dependency
  klass.define_singleton_method :dependency do |meth, &default_block|
    if instance_exec meth, &has_dependency
      warn "Deprecation: Use .override instead of .dependency to override a dependency"
    end
    instance_exec meth, default_block, &define_instance_methods
  end

  # define klass.override
  klass.define_singleton_method :override do |meth, &override_block|
    if !override_block
      raise ArgumentError, "Cannot override #{meth} without an override block" unless override_block
    elsif !instance_exec(meth, &has_dependency)
      raise ArgumentError, "#{meth} is not a dependency of #{klass.inspect}"
    else
      instance_exec meth, override_block, &define_instance_methods
    end
  end

  # override multiple dependencies
  klass.send :define_method, :with_dependencies do |overrides|
    overrides.each { |meth, value| send "with_#{meth}", value }
    self
  end

  klass
end

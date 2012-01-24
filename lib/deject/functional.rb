class Deject
  UninitializedDependency = Class.new StandardError
end

def Deject(klass)
  error_block = lambda do |meth|
    raise Deject::UninitializedDependency, "#{meth} invoked before being defined"
  end

  # define klass.dependency
  klass.define_singleton_method :dependency do |meth, &default_block|

    # define the getter
    define_method meth do
      value = instance_eval &(default_block || error_block[meth])
      define_singleton_method(meth) { value }
      send meth
    end

    # define the override
    define_method :"with_#{meth}" do |value=nil, &block|

      # redefine getter if given a block
      if block
        define_singleton_method meth do
          value = instance_eval &(block || error_block[meth])
          define_singleton_method(meth) { value }
          send meth
        end

      # always return value if given a value
      else
        define_singleton_method(meth) { value }
      end

      self
    end      
  end

  # override multiple dependencies
  klass.send :define_method, :with_dependencies do |overrides|
    overrides.each { |meth, value| send "with_#{meth}", value }
    self
  end

  klass
end

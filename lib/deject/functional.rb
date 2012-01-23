class Deject
  UninitializedDependency = Class.new StandardError
end

def Deject(klass)
  error_block = lambda do |meth|
    raise Deject::UninitializedDependency, "#{meth} invoked before being defined"
  end

  add_deject_to = lambda do |klass|
    # define .dependency
    klass.define_singleton_method :dependency do |meth, &default_block|

      # define the dependency
      define_method meth do
        value = instance_eval &(default_block || error_block[meth])
        define_singleton_method(meth) { value }
        send meth
      end

      # override the dependency
      define_method :"with_#{meth}" do |value|
        define_singleton_method(meth) { value }
        self
      end      
    end
    
    # override multiple dependencies
    klass.send :define_method, :with_dependencies do |overrides|
      overrides.each { |meth, value| send "with_#{meth}", value }
      self
    end
  end

  add_deject_to[klass]
  klass
end

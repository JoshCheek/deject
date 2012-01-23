def Deject(klass)
  Deject.new klass
  klass
end

class Deject
  UninitializedDependency = Class.new StandardError
  attr_accessor :klass
  
  def initialize(klass)
    self.klass = klass
    define_dependency_on_klass
    define_with_dependencies_on_instances
  end
  
  def define_dependency_on_klass
    deject = self
    klass.define_singleton_method :dependency do |name, &block|
      deject.add_dependency name, &block
    end
  end
  
  def define_with_dependencies_on_instances
    deject = self
    klass.send :define_method, :with_dependencies do |overrides|
      overrides.each { |name, value| send :"with_#{name}", value }
      self
    end
  end
  
  def add_dependency(name, &block)
    define_getter name, &block
    define_override name
  end
  
  def define_getter(name, &block)
    deject = self
    klass.send :define_method, name do
      return deject.get self, name if deject.set? self, name
      value = instance_eval &(block or deject.raise_for name)
      deject.set self, name, value
    end
  end
  
  def define_override(name)
    deject = self
    klass.send :define_method, "with_#{name}" do |value|
      deject.set self, name, value
      self
    end
  end
  
  def raise_for(name)
    raise Deject::UninitializedDependency, "#{name} invoked before being defined"
  end
  
  def get(instance, name)
    instance.instance_variable_get :"@#{name}"
  end
  
  def set(instance, name, value)
    instance.instance_variable_set :"@#{name}", value
  end
  
  def set?(instance, name)
    instance.instance_variable_defined? :"@#{name}"
  end
end
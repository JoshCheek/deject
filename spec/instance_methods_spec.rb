require 'spec_helper'

describe 'after initializing a dependency' do
  let(:klass) { Deject Class.new }

  specify '#<dependency> returns the result, initialized for each instance' do
    i = 0
    klass.dependency(:number) { i += 1 }
    klass.new.number.should == 1
    klass.new.number.should == 2
  end

  it 'memoizes the result' do
    i = 0
    klass.dependency(:number) { i += 1 }
    instance = klass.new
    instance.number.should == 1
    instance.number.should == 1
  end

  specify '#with_<dependency> overrides the result' do
    klass.dependency(:number) { 5 }
    klass.new.with_number(6).number.should == 6
  end

  specify '#with_<dependency> can take a value or an init block' do
    klass.dependency(:number1) { 1 }
    klass.dependency(:number2) { 2 }
    i = 0
    instance = klass.new.with_number2 { |instance| i += instance.number1 }
    instance.number2.should == instance.number1
    instance.number2.should == instance.number1
    i.should == instance.number1
  end

  example 'you can override multiple defaults from the instance level by using with_dependencies' do
    klass = Class.new do
      Deject self
      dependency(:a) { 1 }
      dependency(:b) { 2 }
    end
    instance = klass.new.with_dependencies(a: 10, b: 20)
    instance.a.should == 10
    instance.b.should == 20
  end

  specify '#with_<dependency> is passed the instance' do
    klass.dependency(:a) { |instance| instance.b }
    instance = klass.new
    def instance.b() 10 end
    instance.a.should == instance.b
  end
end

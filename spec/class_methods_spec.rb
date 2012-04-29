require 'deject'
require 'spec_helper'


describe 'Klass.dependency' do
  let(:klass) { Deject Class.new }

  before { klass.new.should_not respond_to :dependency }

  context 'with a block' do
    meth   = 'meth'.freeze
    result = 100
    before { klass.dependency(meth) { result } }

    it 'adds the instance method' do
      klass.new.should respond_to meth
    end

    specify 'the instance method defaults to the result of the init block' do
      klass.new.send(meth).should == result
    end

    specify 'the instance method is evaluated within the context of the instance' do
      klass.dependency(:a) { b }
      instance = klass.new
      def instance.b() 10 end
      instance.a.should == instance.b
    end
  end

  context 'without a block' do
    it 'adds the instance method' do
      klass.dependency :abc
      klass.new.should respond_to :abc
    end

    it 'raises an error if called before setting it' do
      klass.dependency :jjjjj
      expect { klass.new.jjjjj }.to raise_error(Deject::UninitializedDependency, /jjjjj/)
    end
  end

  it 'writes a deprecated warning when using dependency to override an existing dependency' do
    catch_stderr { klass.dependency :dep }.should == ""
    catch_stderr { klass.dependency :dep }.should =~ /deprecat/i
  end
end


describe 'Klass.override' do
  let(:klass) { Deject Class.new }

  it "raises an ArgumentError if called for a dependency that doesn't exist" do
    expect { klass.override(:dep) {} }.to raise_error ArgumentError, /dep/
  end

  it "raises an ArgumentError if called without a block" do
    klass.dependency :dep
    expect { klass.override :dep }.to raise_error ArgumentError, /block/
  end

  it 'overrides the dependency on the instance' do
    klass.dependency :dep
    klass.override(:dep) { 123 }
    klass.new.dep.should == 123
  end

  it 'returns the class' do
    klass.dependency :dep
    klass.override(:dep) { 123 }.should equal klass
  end
end

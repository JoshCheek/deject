require 'spec_helper'

describe 'Deject()' do
  let(:klass) { Class.new }

  it 'adds the dependency method to the class' do
    klass.should_not respond_to :dependency
    Deject klass
    klass.should respond_to :dependency
  end

  it 'adds the override_dependency method to the class' do
    klass.should_not respond_to :override
    Deject klass
    klass.should respond_to :override
  end

  it 'returns the class' do
    Deject(klass).should be klass
  end

  let(:default) { :some_default }
  it "can take a list of dependencies that don't have blocks" do
    Deject.register(:abc) { default }
    Deject(klass, :abc).new.abc.should == default
  end
end

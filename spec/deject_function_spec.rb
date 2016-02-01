require 'spec_helper'

describe 'Deject()' do
  let(:klass) { Class.new }

  it 'adds the dependency method to the class' do
    expect(klass).to_not respond_to :dependency
    Deject klass
    expect(klass).to respond_to :dependency
  end

  it 'adds the override_dependency method to the class' do
    expect(klass).to_not respond_to :override
    Deject klass
    expect(klass).to respond_to :override
  end

  it 'returns the class' do
    expect(Deject klass).to equal klass
  end

  let(:default) { :some_default }
  it "can take a list of dependencies that don't have blocks" do
    Deject.register(:abc) { default }
    result = Deject(klass, :abc).new.abc
    expect(result).to eq default
  end
end

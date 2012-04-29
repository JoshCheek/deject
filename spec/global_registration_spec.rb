require 'spec_helper'

describe Deject, '.register and registered' do
  let(:value) { 12 }

  after { Deject.reset }

  it 'accepts a string' do
    Deject.register("abc") { value }
    Deject.registered("abc").call.should == value
    Deject.registered(:abc).call.should == value
  end

  it 'accepts a symbol' do
    Deject.register(:abc) { value }
    Deject.registered("abc").call.should == value
    Deject.registered(:abc).call.should == value
  end

  it 'register raises an ArgumentError if not provided with a block' do
    expect { Deject.register :abc }.to raise_error ArgumentError, /block/i
  end

  it 'remembers what it was registered with' do
    i = 0
    Deject.register(:abc) { i += 1 }
    Deject.registered(:abc).call.should == 1
    i.should == 1
  end

  it 'returns nil when asked for something not registered' do
    Deject.registered(:abc).should == nil
  end

  it 'raises an ArgumentError error if registration clobbers a previously set value' do
    Deject.register(:abc){}
    expect { Deject.register(:abc){} }.to raise_error ArgumentError, /abc/
  end

  it 'knows what has been registered' do
    Deject.should_not be_registered :abc
    Deject.should_not be_registered 'abc'
    Deject.register(:abc) {}
    Deject.should be_registered :abc
    Deject.should be_registered 'abc'
  end
end

require 'spec_helper'

describe Deject, '.register and registered' do
  let(:value) { 12 }

  after { Deject.reset }

  it 'accepts a string' do
    Deject.register("abc") { value }
    expect(Deject.registered("abc").call).to eq value
    expect(Deject.registered(:abc).call).to eq value
  end

  it 'accepts a symbol' do
    Deject.register(:abc) { value }
    expect(Deject.registered("abc").call).to eq value
    expect(Deject.registered(:abc).call).to eq value
  end

  it 'register raises an ArgumentError if not provided with a block' do
    expect { Deject.register :abc }.to raise_error ArgumentError, /block/i
  end

  it 'remembers what it was registered with' do
    i = 0
    Deject.register(:abc) { i += 1 }
    expect(Deject.registered(:abc).call).to eq 1
    expect(i).to eq 1
  end

  it 'returns nil when asked for something not registered' do
    expect(Deject.registered(:abc)).to eq nil
  end

  it 'does not raise an ArgumentError error if registration clobbers a previously set value' do
    Deject.register(:abc){}
    Deject.register(:abc){}
  end

  it 'raises an error if registration clobbers a previously set value when passed safe: true' do
    Deject.register(:abc){}
    expect { Deject.register(:abc, safe: true){} }.to raise_error ArgumentError, /abc/
  end

  it 'knows what has been registered' do
    expect(Deject).to_not be_registered :abc
    expect(Deject).to_not be_registered 'abc'
    Deject.register(:abc) {}
    expect(Deject).to be_registered :abc
    expect(Deject).to be_registered 'abc'
  end
end

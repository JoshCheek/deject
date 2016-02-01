require 'spec_helper'


describe 'Klass.dependency' do
  let(:klass) { Deject Class.new }

  before { expect(klass.new).to_not respond_to :dependency }

  context 'with a block' do
    meth   = 'meth'.freeze
    result = 100
    before { klass.dependency(meth) { result } }

    it 'adds the instance method' do
      expect(klass.new).to respond_to meth
    end

    specify 'the instance method defaults to the result of the init block' do
      expect(klass.new.send meth).to eq result
    end

    specify 'the instance method is evaluated within the context of the caller' do
      klass.dependency(:a) { b }
      instance = klass.new
      def instance.b() 10 end
      def self.b() 20 end
      expect(instance.a).to eq self.b
    end

    specify 'the instance method is passed the instance' do
      klass.dependency(:a) { |instance| instance.b }
      instance = klass.new
      def instance.b() 10 end
      def self.b() end
      expect(instance.a).to eq instance.b
    end
  end

  context 'without a block' do
    it 'adds the instance method' do
      klass.dependency :abc
      expect(klass.new).to respond_to :abc
    end

    it 'raises an error if called before setting it' do
      klass.dependency :jjjjj
      expect { klass.new.jjjjj }.to raise_error(Deject::UninitializedDependency, /jjjjj/)
    end

    it 'uses the global block if provided, passing it the instance' do
      Deject.register(:meth) { |instance| instance.value }
      klass.dependency :meth
      instance = klass.new
      def instance.value() :value end
      expect(instance.meth).to eq :value
    end
  end

  it 'writes a deprecated warning when using dependency to override an existing dependency' do
    expect(catch_stderr { klass.dependency :meth }).to eq ""
    expect(catch_stderr { klass.dependency :meth }).to match /deprecat/i
    expect(catch_stderr { klass.dependency :meth }).to match /meth/i
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
    expect(klass.new.dep).to eq 123
  end

  it 'returns the class' do
    klass.dependency :dep
    result = klass.override(:dep) { 123 }
    expect(result).to equal klass
  end
end

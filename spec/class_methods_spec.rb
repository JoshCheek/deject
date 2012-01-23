require 'deject'


describe 'Klass.dependency' do
  let(:klass) { Deject Class.new }

  before { klass.new.should_not respond_to :dependency }

  context 'Klass.dependency(:name) { init }' do
    meth   = 'meth'.freeze
    result = 100
    before { klass.dependency(meth) { result } }
    
    it 'adds the instance method' do
      klass.new.should respond_to meth
    end

    specify 'the instance method defaults to the result of the init block' do
      klass.new.send(meth).should == result
    end
    
    it 'memoizes the result' do
      i = 0
      klass.dependency(:example) { i += 1 }
      instance = klass.new
      instance.example.should == 1
      instance.example.should == 1
    end

    specify 'the instance method is evaluated within the context of the instance' do
      klass.dependency(:a) { b }
      instance = klass.new
      def instance.b() 10 end
      instance.a.should == instance.b
    end
  end

  context 'Klass.dependency :name' do
    it 'adds the instance method' do
      klass.dependency :abc
      klass.new.should respond_to :abc
    end

    specify 'it raises an error if called without setting it' do
      klass.dependency :jjjjj
      expect { klass.new.jjjjj }.to raise_error(Deject::UninitializedDependency, /jjjjj/)
    end
  end
end

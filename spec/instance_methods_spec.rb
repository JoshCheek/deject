require 'deject'

describe 'after initializing a dependency' do
  let(:klass) { Deject Class.new }

  specify '#<dependency> returns the result, initialized for each instance' do
    i = 0
    klass.dependency(:number) { i += 1 }
    klass.new.number.should == 1
    klass.new.number.should == 2
  end

  specify '#with_<dependency> overrides the result' do
    klass.dependency(:number) { 5 }
    klass.new.with_number(6).number.should == 6
  end
end

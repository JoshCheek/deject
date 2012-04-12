require 'deject'

describe Deject, 'with only a default dependency' do

  it 'lets me specify the default dependency' do
    my_class = Class.new do
      extend Deject
      dependency(:fetcher) { fake_method }
    end
  end

  it 'lets me use the default dependency' do
    my_class = Class.new do
      extend Deject
      dependency(:fetcher) { 3 }
    end

    my_class.new.fetcher.should == 3
  end

  it 'lets me access self in the default dependency' do
    my_class = Class.new do
      extend Deject
      dependency(:fetcher) { self }
    end

    foo = my_class.new

    foo.fetcher.should == foo
  end

  it 'executes the dependency when i ask it to' do
    my_class = Class.new do
      extend Deject
      dependency(:fetcher) { panic }
    end

    foo = my_class.new
    foo.should_receive(:panic)
    foo.fetcher
  end

  it 'does not execute the dependency until i ask it to' do
    my_class = Class.new do
      extend Deject
      dependency(:fetcher) { panic }
    end

    foo = my_class.new
    foo.should_not_receive(:panic)
  end

  it 'caches the default dependency in memory on first use' do
    my_class = Class.new do
      extend Deject
      dependency(:fetcher) { panic }

      attr_reader :i
      def panic
        @i ||= 0
        @i += 1
      end
    end

    foo = my_class.new
    foo.fetcher
    foo.fetcher
    foo.i.should == 1
  end

  it 'allows multiple, independent dependencies' do
    my_class = Class.new do
      extend Deject
      dependency(:runner) { run }
      dependency(:walker) { walk }

      attr_accessor :x
      def run
        self.x += 4
      end

      attr_accessor :y
      def walk
        self.y += 12
      end
    end

    foo = my_class.new
    foo.x = 0
    foo.y = 0

    foo.runner
    foo.x.should == 4
    foo.y.should == 0

    foo.walker
    foo.x.should == 4
    foo.y.should == 12
  end
end

describe Deject, 'with an overridden dependency at the instance level' do

  it 'doesnt call the original dependency' do
    my_class = Class.new do
      extend Deject
      dependency(:fetcher) { panic }
    end

    foo = my_class.new
    foo.fetcher = 7
    foo.should_not_receive(:panic)
    foo.fetcher
  end

  it 'calls the new dependency' do
    my_class = Class.new do
      extend Deject
      dependency(:fetcher) { panic }
    end

    foo = my_class.new
    foo.fetcher = -> { relax }
    self.should_receive(:relax)
    foo.fetcher.call
  end

end

describe Deject, 'with an overridden dependency at the class level' do

  it 'doesnt call the old dependency' do
    my_class = Class.new do
      extend Deject
      dependency(:fetcher) { panic }
    end

    my_class.dependency(:fetcher) { 12 }

    foo = my_class.new
    foo.should_not_receive(:panic)
    foo.fetcher
  end

  it 'calls the new dependency' do
    my_class = Class.new do
      extend Deject
      dependency(:fetcher) { panic }
    end

    my_class.dependency(:fetcher) { relax }

    foo = my_class.new
    foo.should_receive(:relax)
    foo.fetcher
  end

end

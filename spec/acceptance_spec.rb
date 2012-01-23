require 'deject'

describe Deject, 'acceptance tests' do
  example 'setting and overriding' do
    class Client
      def initialize(credentials)
        @credentials = credentials
      end

      def login(name)
        @login = name
      end

      def has_logged_in?(name)
        @login == name
      end

      def initialized_with?(credentials)
        @credentials == credentials
      end
    end

    class Service
      Deject self
      dependency(:client) { Client.new credentials }

      attr_accessor :name

      def initialize(name)
        self.name = name
      end        

      def login
        client.login name
      end

      def credentials
        'skj123@#KLFNV9ajv' # a login key or something, would probably be dejected as well
      end
    end

    # using the default
    service = Service.new('josh')
    service.login
    service.client.should have_logged_in 'josh'
    service.client.should be_initialized_with service.credentials

    # overriding the default at instance level
    client = double('Mock Client 1')
    client.should_receive(:login).with('sally')
    Service.new('sally').with_client(client).login

    client_class, client = double, double
    george = Service.new('george').with_client { client_class.new credentials }
    client_class.should_receive(:new).with(george.credentials).and_return(client)
    client.should_receive(:login).with('george')
    george.login

    # class default remains the same
    Service.new('josh').client.should be_a_kind_of Client

    # overriding the default at class level
    client = double('Mock Client 2')
    client.should_receive(:login).with('mei')
    Service.dependency(:client) { client }
    Service.new('mei').login
  end

  example 'avoid all dependencies by omitting the default' do
    klass = Class.new do
      Deject self
      dependency :client
    end
    expect { klass.new.client }.to raise_error Deject::UninitializedDependency
    client = double
    klass.new.with_client(client).client.should be client
  end
end

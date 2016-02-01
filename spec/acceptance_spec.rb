require 'spec_helper'

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
      dependency(:client) { |service| Client.new service.credentials }

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
    expect(service.client).to have_logged_in 'josh'
    expect(service.client).to be_initialized_with service.credentials

    # overriding the default at instance level
    client = double('Mock Client 1')
    expect(client).to receive(:login).with('sally')
    Service.new('sally').with_client(client).login

    client_class, client = double, double
    george = Service.new('george').with_client { |service| client_class.new service.credentials }
    expect(client_class).to receive(:new).with(george.credentials).and_return(client)
    expect(client).to receive(:login).with('george')
    george.login

    # class default remains the same
    expect(Service.new('josh').client).to be_a_kind_of Client

    # overriding the default at class level
    client = double('Mock Client 2')
    expect(client).to receive(:login).with('mei')
    Service.override(:client) { client }
    Service.new('mei').login
  end

  example 'avoid all dependencies by omitting the default' do
    klass = Class.new do
      Deject self
      dependency :client
    end
    expect { klass.new.client }.to raise_error Deject::UninitializedDependency
    client = double
    expect(klass.new.with_client(client).client).to eq client
  end
end

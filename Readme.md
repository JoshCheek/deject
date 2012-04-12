About
=====

Dependency injection made easy

Installation
============

Add this line to your application's Gemfile:

    gem 'deject'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install deject

Usage
=====

Your Account class:

```ruby
class Account
  extend Deject
  dependency(:authenticator) { RealAuthenticator.new }

  def authenticate
    authenticator.authenticate_with street_creds
  end
end
```

Your Account tests:

```ruby
describe Account do

  it 'authenticates well' do
    fake_authenticator = FakeAuthenticator.new
    subject.authenticator = fake_authenticator

    subject.authenticate

    fake_authenticator.should be_authenticated
  end

end
```

Contributing
============

1. Fork it
2. Write features with tests
3. Create new Pull Request

License
=======

Copyright (c) 2012 Joshua Cheek

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

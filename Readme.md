About
=====

Simple dependency injection

Install
=======

On most systems:

    $ gem install deject # coming soon

On some systems:

    $ sudo gem install deject

If you have to use sudo and you don't know why, it's because you need to set your GEM_HOME environment variable.

Example
=======
```ruby

require 'deject'

# Represents some client like https://github.com/voloko/twitter-stream
# Some client that will be used by our service
class Client
  def initialize(credentials)
    @credentials = credentials
  end

  def login(name)
    @login = name
  end

  def has_logged_in?(name) # !> `&' interpreted as argument prefix
    @login == name
  end

  def initialized_with?(credentials)
    @credentials == credentials
  end
end


class Service
  Deject self # <-- we'll talk more about this later

  # you can basically think of the block as a factory that
  # returns a client. It is evaluated in the context of the instance
  # ...though I'm not sure that's a good strategy to employ
  #    (I suspect it would be better that these return constants as much as possible)
  dependency(:client) { Client.new credentials }

  attr_accessor :name

  def initialize(name)
    self.name = name
  end

  def login
    client.login name
  end

  def credentials
    # a login key or something, would probably be dejected as well
    # to retrieve the result from some config file or service
    'skj123@#KLFNV9ajv'
  end
end

# using the default
service = Service.new('josh')
service.login
service.client # => #<Client:0x007ff97a92d9b8 @credentials="skj123@#KLFNV9ajv", @login="josh">
service.client.has_logged_in? 'josh' # => true
service.client.initialized_with? service.credentials # => true

# overriding the default at instance level
client_mock = Struct.new :recordings do
  def method_missing(*args)
    self.recordings ||= []
    recordings << args
  end
end
client = client_mock.new
sally = Service.new('sally').with_client client # <-- you can also override with a block

sally.login
client.recordings # => [[:login, "sally"]]

sally.login
client.recordings # => [[:login, "sally"], [:login, "sally"]]
```

Reasons
=======

Why write this?
---------------

Hard dependencies kick ass. They make your code clear and easy to understand.
But, of course, they're hard, you can't change them (or can't reasonably change them).
So when you go to test, it sucks. When you want to reuse, it sucks. How to get around this?
Inject your dependencies.

And while it's not the worst thing in the world to do custom dependency injection in Ruby,
it can still get obnoxious. What do you do? There's basically two options:

1. Add it as an argument when initializing (or _possibly_ when invoking your method). This works
   fine if you aren't already doing anything complicated with your arguments. If you can just throw
   an optional arg in there for the dependency, giving it a default of the hard dependency, then
   it's not too big of a deal. But what if you have two dependencies? Then you can't use optional
   arguments, because how will you know which is which? What if you're already taking optional args?
   Then again, you can't pass this in optionally. So you have to set it to an ordinal argument, which
   means that everywhere you use the thing, you have to deal with the dependency. It's cumbersome and ugly.
   Or you can pass it in with an options hash, but what if you're already taking a hash (as I was when
   I decided I wanted this) and it's not for this object? Then you have to namespace the common options
   such that you can tell them apart, it's gross (e.g. passing html options to a form in Rails), and you
   only need to do it for something that users shouldn't need to care about unless they really want to.

2. Defining methods to return the dependency that can be overridden by setting the value. This is a heavier
   choice than the above, but it can become necessary. Define an `attr_writer :whatever` and a getter
   whose body looks like `@whatever ||= HardDependency.new`. Not the worst thing in the world, but it takes
   about four lines and clutters things up. What's more, it must be set with a setter, and setters always
   return the RHS of the assignment. So to override it, you have to have three lines where you probably only want one.
   And of course, having a real method in there is a statement. It says "this is the implementation", people
   don't override methods all willy nilly, I'd give dirty looks to colleagues if they overrode it as was convenient.
   For instance, say you _always_ want to override the default (e.g. a FakeUser in the test environment and User in
   development/production environments). Then you have to open the class and redefine it in an initialization file.
   Not cool.

Deject handles these shortcomings with the default ways to inject dependencies. Declaring something a dependency
inherently identifies it as overridable. Overriding it by environment is not shocking or unexpected, and only requires one line,
and has the advantage of closures during overriding -- as opposed to having to metaprogramming to set that default.

It makes it very easy to declare and to override dependencies, by adding an inline call to the override.
You don't have to deal with arguments, you don't have to define methods, it defines the methods for you
and gives you an easy way to inject a new value. In the end, it's simpler and easier to understand.


Statements I am trying to make by writing this
----------------------------------------------

Dependencies should be soft by default, dependency injection can have a place in Ruby
(even though I'll probably get made fun of for it). I acknowledge that I really enjoyed
the post [Why I love everything you hate about Java](http://magicscalingsprinkles.wordpress.com/2010/02/08/why-i-love-everything-you-hate-about-java/).
Though I agreed with a lot of the rebuttals in the comments as well.

I intentionally didn't do this with module inclusion. Module inclusion has become a cancer
(I'll probably write a blog about that later). _Especially_ the way people abuse the `self.included` hook.
I wanted to show people that you don't _HAVE_ to do that. There's no reason your module can't have
a method that is truthful about its purpose, something like `MyModule.apply_to MyClass`, it can include and extend
in there all it wants. That's fine, that's obvious, it isn't lying. But when people `include MyModule`
just so they can get into the included hook (where they almost never need to) and then **EXTEND** the class... grrrrr.

And of course, after I decided I wasn't going to directly include / extend the module, I began
thinking about how to get Deject onto the class. `Deject.dejectify SomeClass`? Couldn't think of
a good verb. But wait, do I _really_ need a verb? I went and read
[Execution in the Kingdom of Nouns](http://steve-yegge.blogspot.com/2006/03/execution-in-kingdom-of-nouns.html)
and decided I was okay with having a method that applies it, hence `Deject SomeClass`. Not a usual practice
but not everything needs to be OO. Which led to the next realization that I didn't need a module at all.

So, there's two implementations. You can set which one you want to use with an environment variable (not that you care).
The first is "functional" which is to say that I was trying to channel functional ideas when writing it. It's really just one
big function that defines and redefines methods. Initially I hated this, I found it very difficult to read (might have been
better if Ruby had macros), I had to add comments in to keep track of what was happening.
But then I wrote the object oriented implementation, and it was pretty opaque as well.
Plus there were a lot of things I wanted to do that were very difficult to accomplish, and it was much longer.

So in the end, I'm hoping someone takes the time to look at both implementations and gives me feedback on their thoughts
Is one better? Are they each better in certain ways? Can this code be made simpler? Any feedback is welcome.

Oh, I also intentionally used closures over local variables rather than instance variables, because I
wanted to make people realize it's better to use setters and getters than to directly access instance variables
(to be fair, there are some big names that [disagree with](http://www.ruby-forum.com/topic/211544#919648) me on this).
I think most people directly access ivars because they haven't found themselves in a situation where it mattered.
But what if `attr_accessor` wound up changing implementations such that it didn't use ivars? "Ridiculous" I can hear
people saying, but it's not so ridiculous when you realize that you can remove 4 redundant lines by inheriting from
a Struct. If you use indirect access, everything still works just fine. And structs aren't the only place this occurs,
think about ActiveRecord::Base, it doesn't use ivars, so if you use attr_accessor in your model somewhere, you need to
know how a given attribute was defined so that you can know if you should use ivars or not... terrible. Deject's functional
implementation does not use ivars, you **must** use the getter and the overrider (there isn't currently a setter).
That is intentional (though I used ivars in the OO implementation).


Todo
====

Maybe raise an error if you call `with_whatever` and pass no args.
Maybe add a setter rather than only provide the overrider.

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

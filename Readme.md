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

# register a global value (put this into an initializer or dependency injection file)
# if you are worried about clobbering a previously registered value, invoke with `:player2, safe: true`
# this is turned off by default because I found that code reloading was horking everything up
Deject.register(:player2) { HumanPlayer.new }

# some players you want to inject
HumanPlayer    = Class.new
ComputerPlayer = Class.new
MockPlayer     = Class.new

# Game needs some players, but doesn't know what kinds to use!
Game = Struct.new :name do
  Deject self
  dependency(:player1) { ComputerPlayer.new } # Game#player1 will default to computer player
  dependency :player2                         # Game#player2 will default to registered value
end

# declared with a block, so will default to block value
Game.new.player1.class # => ComputerPlayer

# declared without a block, so will default to the registered value for player2
Game.new.player2.class # => HumanPlayer

# we can override for this entire class
Game.override(:player2) { MockPlayer.new }
Game.new.player2.class # => MockPlayer

# we can override for some specific instance using either a block or a value
# instance level overriding is done using method with_<dependnecy_name>, which returns the instance
Game.new.with_player2 { HumanPlayer.new }.player2.class # => HumanPlayer
Game.new.with_player2(ComputerPlayer.new).player2.class # => ComputerPlayer

# anywhere a block is used, the instance will be passed into it
monopoly = Game.new 'Monopoly'
chatty_player = Struct.new :message

monopoly.with_player1 { |game| chatty_player.new "Your mom sucks at #{game.name}" } # an antagonistic player
monopoly.player1.message # => "Your mom sucks at Monopoly"

Game.override(:player2) { |game| chatty_player.new "You're very good at the #{game.name}s!" } # a supportive player
monopoly.player2.message # => "You're very good at the Monopolys!"

# results are memoized:
monopoly.name = 'Clue Jr.'
monopoly.player2.message # => "You're very good at the Monopolys!"
```


Note that dependencies using the defaults can be declared when dejecting the class:

```ruby
class Game
  # this
  Deject self
  dependency :player1
  dependency :player2

  # is the same as this
  Deject self, :player1, :player2
end
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
it still gets obnoxious.


Example: passing dependency when initializing

```ruby
class SomeClass
  attr_accessor :some_dependency

  # cannot set this unless also setting arg2
  def initialize(arg1, arg2=default, some_dependency=default)
  end

  # cannot set arg2 without being forced to set dependency
  def initialize(arg1, some_dependency=default, arg2=default)
  end

  # forced to deal with the dependency *every place* you use this class
  def initialize(some_dependency, arg1, arg2=default)
  end

  # okay, this isn't too bad unless:
  #   1) You want to change the default
  #   2) You only have one other optional arg
  #      as you must degrade the interface for this new requirement
  #   3) Your options aren't simple,
  #     (e.g. will be passed to some other class as I was dealing with when I decided to write this),
  #     then you will have to namespace your options and theirs
  def initializing(arg1, options={})
    arg2 = options.fetch(:arg2) { default }
    self.some_dependency = options.fetch(:some_dependency) { default }
  end
end
```


Example: try to set it in a method that you change later

```ruby
class SomeClass
  class << self
    attr_writer :some_dependency
    def some_dependency(instance)
      @some_dependency ||= default
    end
  end

  attr_writer :some_dependency
  def some_dependency
    @some_dependency ||= self.class.some_dependency self
  end
end

# blech, that's:
#   1) complicated -- as in difficult to easily look at and understand
#      especially if you were to have more than one dependency
#   2) probably needs explicit tests given that there's quite a bit of
#      indirection and behaviour going on in here
#   3) the class level override can't take into account anything unique
#      about the instance (ie it must be an object, so must work for all instances)
#   4) instances must be overridden like this: instance = SomeClass.new
#                                              instance.some_dependency = override
#                                              instance.whatever
#      whereas Deject would be like this: SomeClass.new.with_some_dependency(override).whatever
```


Example: redefine the method

```ruby
class SomeClass
  def some_dependency
    @some_dependency ||= default
  end
end

# then later in some other file, totally unbeknownst to anyone reading the above code
class SomeClass
  def some_dependency
    @some_dependency ||= new_default
  end
end

# Want to piss off your colleagues? Imagine how long it will take them to figure out
# why this code doesn't behave as they expect. What's more, guess what happens when
# someone refactors that main class... your redefinition of some_dependency just becomes
# a definition. It doesn't fail, it has no idea about the method it's overriding,
# or the changes that happened to it.
```

Compare the above examples to Deject

```ruby
class SomeClass
  Deject self
  dependency(:some_dependency) { |instance| default }
end

# straightforward (no one will be surprised when this changes),
# declarative so easy to understand
# convenient to override for all instances or any specific instance.
```



About the Code
--------------

There have been maybe four or five implementations of Deject throughout it's life (though I think only two were ever committed to the repo).
I ultimately chose the current implementation because it was the easiest to add features to.
That said, it is not canonical Ruby style code, and will take an open mind to work with.

I intentially chose to avoid using a module because this is pervasive and widely abused in Ruby, for more, see my [blog post](http://blog.8thlight.com/josh-cheek/2012/02/03/modules-called-they-want-their-integrity-back.html).
I thought a long time about how to add the functionality, thinking about `Deject.execute` or some other verb that the Deject noun could perform.
But I couldn't think of a good one. But wait, do I _really_ need a verb? I went and re-read [Execution in the Kingdom of Nouns](http://steve-yegge.blogspot.com/2006/03/execution-in-kingdom-of-nouns.html)
and decided I was okay with having a method named after the class that applies it, hence `Deject SomeClass`. Not a usual practice
but not unheard of, and I don't think it makes sense to force an OO like interface where it doesn't fit well.

We use `with_<dependency>` instead of `dependency=` because taking blocks is grotesque with assignment methods. I have a general
disdain for assignment methods as they encourage a mindset that doesn't appreciate the advantages of OO.
_"When you have a 'setter' on an object, you have turned an object back into a data structure" -- Alan Kay_.
Furthermore, I nearly always want to be able to override the result inline, which you can't easily do with assignment methods
as the interpreter guarantees they return the RHS (best solution would be to `tap` the object).
The `with_<name>` pattern is a common pattern in [IO](http://iolanguage.com/).

In general, all variables are stored as locals in closures rather than instance variables on the object. This is
partially due to the implementation (alternative implementations used ivars), and partially because I wanted to
make a point that relying on ivars is a bad practice: You cannot change implementations (without changing all the code using the ivar)
 if you use the ivar instead of the getter (e.g. switch from `attr_accessor` to a struct, or in an `ActiveRecord::Base` subclass, moving a variable
from an `attr_accessor` into the database). Furthermore, directly accessing ivars requires you to know when they were
initialized, which you should not have to deal with, and this also impedes you from extracting the variable into a
method you inherit from a module (the module can't lazily initialize it, because their methods are completely bypassed).
And it even impedes refactoring. If you previously initialized `@full_name` in the `#initialize` method, you could not then decide to
refactor `def fullname() @fullname end` into `def fullname() "#@firstname #@lastname" end` because users of
fullname aren't using the method, they're accessing the variable directly. In general, I think it is best to
encapsulate from everyone, including other methods in the same object. In Deject you don't have a choice,
you use the methods because there are no variables. If you'd like to read an argument against my position on this,
Rick Denatale summarizes Kent Beck's opinion on [ruby-talk](http://www.ruby-forum.com/topic/211544#919648).

Deject does not litter your classes or instances with unexpected methods or variables.


Special Thanks
==============

To the [8th Light](http://8thlight.com/)ers who have provided feedback, questions, and criticisms.


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

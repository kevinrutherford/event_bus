# EventBus

A simple pubsub event bus for Ruby applications.

[![Build Status](https://travis-ci.org/kevinrutherford/event_bus.png)](https://travis-ci.org/kevinrutherford/event_bus)
[![Dependency
Status](https://gemnasium.com/kevinrutherford/event_bus.png)](https://gemnasium.com/kevinrutherford/event_bus)

* <https://rubygems.org/gems/event_bus>
* <http://rubydoc.info/gems/event_bus/frames>
* <https://github.com/kevinrutherford/event_bus>

## Features

* Simple, global support for the Observer pattern, aka Publisher-Subscriber.
* Publish and subscribe to events throughout your Ruby application.
* Listen for events without coupling to the publishing object or class.
* Subscribe to events using names or regex patterns.
* Works with Rails.

## Installation

Install the gem

```
gem install event_bus
```

Or add it to your Gemfile and run `bundle`.

``` ruby
gem 'event_bus'
```

## Usage

Subscribe a method call to an event:

```ruby
EventBus.subscribe('order-placed', StatsRecorder.new, :order_placed)
```

```ruby
class StatsRecorder
  def order_placed(details)
    order = details[:order]
    //...
  end
end
```

Or subscribe a block:

```ruby
EventBus.subscribe('order-placed') do |details|
  order = details[:order]
  //...
end
```

Fire the event whenever something significant happens in your application:

```ruby
class PlaceOrder
  //...
  EventBus.announce('order-placed', :order => current_order, :customer => current_user)
end
```

See the specs for more detailed usage scenarios.

## Compatibility

Tested with Ruby 1.8.7, 1.9.x, JRuby, Rubinius.
See the [build status](https://travis-ci.org/kevinrutherford/event_bus)
for details.

## License

(The MIT License)

Copyright (c) 2013 Kevin Rutherford

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the 'Software'), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.


# EventBus

A simple pubsub event bus for Ruby applications.

[![Build Status](https://travis-ci.org/kevinrutherford/event_bus.png)](https://travis-ci.org/kevinrutherford/event_bus)
[![Dependency
Status](https://gemnasium.com/kevinrutherford/event_bus.png)](https://gemnasium.com/kevinrutherford/event_bus)
[![Code
Climate](https://codeclimate.com/github/kevinrutherford/event_bus.png)](https://codeclimate.com/github/kevinrutherford/event_bus)

* Gem: <https://rubygems.org/gems/event_bus>
* API docs: <http://rubydoc.info/gems/event_bus/frames>
* Source code: <https://github.com/kevinrutherford/event_bus>

## Features

* Simple, global support for the Observer pattern, aka Publisher-Subscriber.
* Publish and subscribe to events throughout your Ruby application.
* Listen for events without coupling to the publishing object or class.
* Subscribe to events using names or regex patterns.
* Works with Rails.
* Works without Rails.
* Completely synchronous (use the
  [event_bg_bus](https://rubygems.org/gems/event_bg_bus) gem for async operation
  using Sidekiq).

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

### Publishing events

Publish events whenever something significant happens in your application:

```ruby
class PlaceOrder
  //...
  EventBus.announce(:order_placed, order: current_order, customer: current_user)
end
```

The event name (first argument) can be a String or a Symbol.
The Hash is optional and supplies a payload of information to any subscribers.

(If you don't like the method name `announce` you can use `publish` or
`broadcast` instead.)

### Subscribing to events

There are three ways to subscribe to events.

1. Subscribe a listener object:

    ```ruby
    EventBus.subscribe(StatsRecorder.new)
    ```

    The event will be handled by a method whose name matches the event name:

    ```ruby
    class StatsRecorder
      def order_placed(payload)
        order = payload[:order]
        //...
      end
    end
    ```

    If the object has no matching method, it doesn't receive the event.

2. Specify the method to be called when the event fires:

    ```ruby
    EventBus.subscribe(:order_placed, StatsRecorder.new, :print_order)
    ```

    In this case the event will be handled by the `print_order` method:

    ```ruby
    class StatsRecorder
      def print_order(payload)
        order = payload[:order]
        //...
      end
    end
    ```

    The first argument to `subscribe` can be a String,
    a Symbol or a Regexp:

    ```ruby
    EventBus.subscribe(/order/, StatsRecorder.new, :print_order)
    ```

3. Subscribe a block:

    ```ruby
    EventBus.subscribe(:order_placed) do |payload|
      order = payload[:order]
      //...
    end
    ```

    The argument to `subscribe` can be a String, a Symbol or a Regexp:

    ```ruby
    EventBus.subscribe(/order/) do |payload|
      order = payload[:order]
      //...
    end
    ```

See the specs for more detailed usage scenarios.

## Compatibility

Tested with Ruby 2.1, 2.0, 1.9.x, JRuby.
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


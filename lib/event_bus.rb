require_relative 'event_bus/registrations'

class EventBus

  class << self

    #
    # Announce an event to any waiting listeners.
    #
    # The +event_name+ is added to the +payload+ hash (with the key +:event_name+)
    # before being passed on to listeners.
    #
    # @param event_name [String, Symbol] the name of your event
    # @param payload [Hash] the information you want to pass to the listeners
    # @return [EventBus] the EventBus, ready to be called again.
    #
    def publish(event_name, payload = {})
      case event_name
      when Symbol, String
        registrations.announce(event_name, payload)
        self
      else
        raise ArgumentError.new('The event name must be a string or a symbol')
      end
    end

    alias :announce :publish
    alias :broadcast :publish

    #
    # Subscribe to a set of events.
    #
    # If +blk+ is supplied, it will be called with any event whose name
    # matches +pattern+.
    #
    # If no block is given, and if +pattern+ is a String or a Regexp,
    # a method will be called on +listener+ whenever an event matching
    # +pattern+ occurs. In this case, if +method_name+ is supplied the
    # EventBus will look for, and call, a method of that name on +listener+;
    # otherwise if +method_name+ is not given, the EventBus will attempt to
    # call a method whose name matches the event's name.
    #
    # Finally, if no block is given and +pattern+ is not a String or a Regexp,
    # then +pattern+ is taken to be a listener object and the EventBus will
    # attempt to call a method on it whose name matches the event's name.
    #
    # Either +listener+ or +blk+ must be provided, both never both.
    #
    # When a matching event occurs, either the block is called or the +method_name+
    # method on the +listener+ object is called.
    #
    # @param pattern [String, Regexp] listen for any events whose name matches this pattern
    # @param listener the object to be notified when a matching event occurs
    # @param method_name [Symbol] the method to be called on +listener+ when a matching event occurs
    # @return [EventBus] the EventBus, ready to be called again.
    #
    def subscribe(pattern, listener = nil, method_name = nil, &blk)
      case pattern
      when Regexp, String
        subscribe_pattern(pattern, listener, method_name, &blk)
      else
        subscribe_obj(pattern)
      end
      self
    end

    alias :listen_for :subscribe

    #
    # Delete all current listener registrations
    #
    # @return the EventBus, ready to be called again.
    #
    def clear
      registrations.clear
      self
    end

    #
    # (experimental)
    #
    def register(listener)
      listener.events_map.each do |pattern, method_name|
        registrations.add(pattern, listener, method_name)
      end
      self
    end

    private

    def subscribe_pattern(pattern, listener, method_name, &blk)
      if listener
        raise ArgumentError.new('You cannot give both a listener and a block') if block_given?
        raise ArgumentError.new('You must supply a method name') unless method_name
        registrations.add_method(pattern, listener, method_name)
      else
        raise ArgumentError.new('You must provide a listener or a block') unless block_given?
        registrations.add_block(pattern, &blk)
      end
    end

    def subscribe_obj(listener)
      registrations.add_block(/.*/) do |payload|
        method = payload[:event_name].to_sym
        listener.send(method, payload) if listener.respond_to?(method)
      end
    end

    def registrations
      Registrations.instance
    end

  end

end


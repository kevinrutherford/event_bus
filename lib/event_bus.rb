require 'singleton'

class EventBus

  class << self

    #
    # Announce an event to any waiting listeners.
    #
    # The +event_name+ is added to the +details+ hash (with the key +:event_name+)
    # before the event is passed on to listeners.
    #
    # @param event_name [String, Symbol] the name of your event
    # @param details [Hash] the information you want to pass to the listeners
    # @return the EventBus, ready to be called again.
    #
    def publish(event_name, details = {})
      registrations.announce(event_name, details)
      self
    end

    alias :announce :publish
    alias :broadcast :publish

    #
    # Subscribe to all events matching +pattern+.
    #
    # Either +listener+ or +blk+ must be provided, both never both.
    #
    # When a matching event occurs, either the block is called or the +method_name+
    # method on the +listener+ object is called.
    #
    # @param pattern [String, Regex] listen for any events whose name matches this pattern
    # @param listener the object to be notified when a matching event occurs
    # @param method_name [Symbol] the method to be called on +listener+ when a matching event occurs
    # @return the EventBus, ready to be called again.
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
      registrations.add_block(/.*/) {|payload|
        method = payload[:event_name].to_sym
        listener.send(method, payload) if listener.respond_to?(method)
      }
    end

    private :subscribe_obj, :subscribe_pattern

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

    def registrations
      Registrations.instance
    end

  end

  class Registrations
    include Singleton

    def initialize
      clear
    end

    def announce(event_name, details)
      info = {:event_name => event_name}.merge(details)
      @listeners.each do |listener|
        listener.respond(event_name, info)
      end
    end

    def clear
      @listeners = []
    end

    def add(pattern, listener, method_name, &blk)
      if listener
        add_method(pattern, listener, method_name)
      else
        add_block(pattern, blk)
      end
    end

    def add_method(pattern, listener, method_name)
      @listeners << Registration.new(pattern, listener, method_name)
    end

    def add_block(pattern, &blk)
      @listeners << BlockRegistration.new(pattern, blk)
    end

    private

    Registration = Struct.new(:pattern, :listener, :method_name) do
      def respond(event_name, details)
        listener.send(method_name, details) if pattern === event_name
      end
    end

    BlockRegistration = Struct.new(:pattern, :block) do
      def respond(event_name, details)
        block.call(details) if pattern === event_name
      end
    end

  end

end


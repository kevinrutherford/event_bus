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
    def publish(event_name, details)
      registrations.announce(event_name, details)
      self
    end

    alias :announce :publish
    alias :broadcast :publish

    #
    # Register a single listener.
    #
    # @param pattern [String, Regex] listen for any events whose name matches this pattern
    # @param listener the object to be notified when a matching event occurs
    # @param method_name [Symbol] the method to be called on listener when a matching event occurs
    # @return the EventBus, ready to be called again.
    #
    def subscribe(pattern, listener, method_name)
      registrations.register(pattern, listener, method_name)
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
        registrations.register(pattern, listener, method_name)
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

    def register(pattern, listener, method_name)
      @listeners << Registration.new(pattern, listener, method_name)
    end

    private

    Registration = Struct.new(:pattern, :listener, :method_name) do
      def respond(event_name, details)
        listener.send(method_name, details) if pattern === event_name
      end
    end

  end

end


require 'singleton'

class EventBus

  #
  # Announce an event to any waiting listeners.
  #
  # @param event_name [String, Symbol] the name of your event
  # @param details [Hash] the information you want to pass to the listeners
  # @return the EventBus, ready to be called again.
  #
  def self.announce(event_name, details)
    Registrations.instance.announce(event_name, details)
    self
  end

  #
  # Register a single listener.
  #
  # @param pattern [String, Regex] listen for any events whose name matches this pattern
  # @param listener the object to be notified when a matching event occurs
  # @param method_name [Symbol] the method to be called on listener when a matching event occurs
  # @return the EventBus, ready to be called again.
  #
  def self.listen_for(pattern, listener, method_name)
    Registrations.instance.register(pattern, listener, method_name)
    self
  end

  #
  # Delete all current listener registrations
  #
  # @return the EventBus, ready to be called again.
  #
  def self.clear
    Registrations.instance.clear
    self
  end

  #
  # (experimental)
  #
  def self.register(listener)
    listener.events_map.each do |pattern, method_name|
      Registrations.instance.register(pattern, listener, method_name)
    end
    self
  end

  private

  class Registrations
    include Singleton

    def initialize
      clear
    end

    def announce(event_name, details)
      @listeners.each do |listener|
        listener.respond(event_name, details)
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


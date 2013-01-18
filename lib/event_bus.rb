require 'singleton'

class EventBus

  def self.announce(event_name, details)
    Registrations.instance.announce(event_name, details)
    self
  end

  def self.clear
    Registrations.instance.clear
    self
  end

  def self.listen_for(pattern, listener, method_name)
    Registrations.instance.register(pattern, listener, method_name)
    self
  end

  def self.register(listener)
    listener.events_map.each do |pattern, method_name|
      Registrations.instance.register(pattern, listener, method_name)
    end
    self
  end

  private

  class Registrations
    include Singleton

    Registration = Struct.new(:pattern, :listener, :method_name) do
      def respond(event_name, details)
        listener.send(method_name, details) if pattern === event_name
      end
    end

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

  end

end


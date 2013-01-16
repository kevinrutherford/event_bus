require 'singleton'

class EventBus
  include Singleton

  def self.announce(event_name, details)
    instance.announce(event_name, details)
  end

  def self.clear
    instance.clear
  end

  def self.listen_for(pattern, listener, method_name)
    instance.register(pattern, listener, method_name)
  end

  def self.register(listener)
    listener.events_map.each do |pattern, method_name|
      instance.register(pattern, listener, method_name)
    end
  end

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


require 'singleton'

class EventBus

  private

  class Registrations
    include Singleton

    def initialize
      clear
    end

    def announce(event_name, payload)
      full_payload = {event_name: event_name}.merge(payload)
      @listeners.each do |listener|
        listener.respond(event_name, full_payload)
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
      def respond(event_name, payload)
        listener.send(method_name, payload) if pattern === event_name
      end
    end

    BlockRegistration = Struct.new(:pattern, :block) do
      def respond(event_name, payload)
        block.call(payload) if pattern === event_name
      end
    end

  end

end


require 'singleton'

class EventBus

  private

  class Registrations
    include Singleton

    def announce(event_name, payload)
      full_payload = {event_name: event_name}.merge(payload)
      listeners.each do |listener|
        pass_event_to listener, event_name, full_payload
      end
    end

    def clear
      listeners.clear
    end

    def add_method(pattern, listener, method_name)
      listeners << Registration.new(pattern, listener, method_name)
    end

    def add_block(pattern, &blk)
      listeners << BlockRegistration.new(pattern, blk)
    end

    def on_error(&blk)
      @error_handler = blk
    end

    private

    def listeners
      @listeners ||= []
    end

    def error_handler
      @error_handler
    end

    def pass_event_to(listener, event_name, payload)
      begin
        listener.respond(event_name, payload)
      rescue => error
        error_handler.call(listener.receiver, payload.merge(error: error)) if error_handler
      end
    end

    Registration = Struct.new(:pattern, :listener, :method_name) do
      def respond(event_name, payload)
        listener.send(method_name, payload) if pattern === event_name
      end

      def receiver
        listener
      end
    end

    BlockRegistration = Struct.new(:pattern, :block) do
      def respond(event_name, payload)
        block.call(payload) if pattern === event_name
      end

      def receiver
        block
      end
    end

  end

end


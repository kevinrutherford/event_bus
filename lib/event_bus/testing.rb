class EventBus
  def self.with_temporary_subscriber(pattern, listener = nil, method_name = nil)
    subscribe(pattern, listener, method_name)
    temporary_subscriber = registrations.last_subscriber

    yield
  ensure
    registrations.remove_subscriber(temporary_subscriber)
  end

  private
  class Registrations
    def remove_subscriber(subscriber)
      listeners.delete subscriber
    end

    def last_subscriber
      listeners.last
    end
  end
end

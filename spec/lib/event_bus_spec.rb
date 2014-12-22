require 'spec_helper'

describe EventBus do
  let(:listener) { double(:listener, handler: true) }

  before do
    EventBus.clear
  end

  describe 'a temporary subscriber' do
    example 'receives events during the subscription block' do
      expect(listener).to receive(:handler).with(event_name: 'test')
      EventBus.with_temporary_subscriber(/test/, listener, :handler) { EventBus.publish 'test'}
    end

    example 'does not receive events after the subscription block' do
      expect(listener).to_not receive(:handler).with(event_name: 'test')
      EventBus.with_temporary_subscriber(/test/, listener, :handler) {  }
      EventBus.publish 'test'
    end
  end

  describe 'publishing' do

    it 'accepts a string for the event name' do
      expect(listener).to receive(:handler).with(event_name: 'aa123bb')
      EventBus.subscribe(/aa123bb/, listener, :handler)
      EventBus.publish('aa123bb')
    end

    it 'accepts a symbol for the event name' do
      expect(listener).to receive(:handler).with(event_name: :aa123bb)
      EventBus.subscribe(/aa123bb/, listener, :handler)
      EventBus.publish(:aa123bb)
    end

    it 'rejects any other type as the event name' do
      expect { EventBus.publish(123) }.to raise_exception(ArgumentError)
    end

    it 'adds the event name to the payload' do
      expect(listener).to receive(:handler).with(event_name: 'aa123bb', a: 56)
      EventBus.subscribe('aa123bb', listener, :handler)
      EventBus.publish('aa123bb', a: 56)
    end

    it 'allows the payload to be omitted' do
      expect(listener).to receive(:handler).with(event_name: 'aa123bb')
      EventBus.subscribe('aa123bb', listener, :handler)
      EventBus.publish('aa123bb')
    end

  end

  describe 'publishing with errors' do
    let(:error) { RuntimeError.new }
    let(:erroring_listener) { double(:erroring_listener) }
    let(:error_handler) { double(:error_handler, handle_error: true) }

    before do
      allow(erroring_listener).to receive(:handler) { raise error }
    end

    it 'sends the event to the second listener when the first errors' do
      expect(listener).to receive(:handler).with(event_name: 'aa123bb')
      EventBus.subscribe('aa123bb', erroring_listener, :handler)
      EventBus.subscribe('aa123bb', listener, :handler)
      EventBus.publish('aa123bb')
    end

    context 'with an error handler' do
      before do
        EventBus.on_error do |listener, payload|
          error_handler.handle_error(listener, payload)
        end
      end

      it 'when the listener is an object' do
        expect(error_handler).to receive(:handle_error).with(erroring_listener, event_name: 'aa123bb', error: error)
        EventBus.subscribe('aa123bb', erroring_listener, :handler)
        EventBus.publish('aa123bb')
      end

      it 'when the listener is a block' do
        expect(error_handler).to receive(:handle_error).with(instance_of(Proc), event_name: 'aa123bb', error: error)
        EventBus.subscribe('aa123bb') {|info| raise error }
        EventBus.publish('aa123bb')
      end

    end

  end

  describe 'subscribing' do

    context 'with a regex pattern' do
      it 'sends the event to a matching listener' do
        expect(listener).to receive(:handler).with(a: 1, b: 2, event_name: 'aa123bb')
        EventBus.subscribe(/123b/, listener, :handler)
        EventBus.publish('aa123bb', a: 1, b: 2)
      end

      it 'does not send the event to non-matching listeners' do
        expect(listener).to_not receive(:handler)
        EventBus.subscribe(/123a/, listener, :handler)
        EventBus.publish('aa123bb', a: 1, b: 2, event_name: 'aa123bb')
      end
    end

    context 'with a string pattern' do
      it 'sends the event to a matching listener' do
        expect(listener).to receive(:handler).with(a: 1, b: 2, event_name: 'aa123bb')
        EventBus.subscribe('aa123bb', listener, :handler)
        EventBus.publish('aa123bb', a: 1, b: 2)
      end

      it 'does not send the event to non-matching listeners' do
        expect(listener).to_not receive(:handler)
        EventBus.subscribe('blah', listener, :handler)
        EventBus.publish('aa123bb', a: 1, b: 2, event_name: 'aa123bb')
      end
    end

    context 'with a symbol pattern' do
      it 'sends the event to a matching listener' do
        expect(listener).to receive(:handler).with(a: 1, b: 2, event_name: :aa123bb)
        EventBus.subscribe(:aa123bb, listener, :handler)
        EventBus.publish(:aa123bb, a: 1, b: 2)
      end

      it 'does not send the event to non-matching listeners' do
        expect(listener).to_not receive(:handler)
        EventBus.subscribe(:blah, listener, :handler)
        EventBus.publish('aa123bb', a: 1, b: 2, event_name: 'aa123bb')
      end
    end

    context 'subscribing a block' do
      let(:spy) { double(:spy, block_called: nil) }

      before {
        EventBus.subscribe('aa123bb') {|info| spy.block_called(info) }
      }

      it 'calls the block when the event matches' do
        expect(spy).to receive(:block_called).with(a: 1, b: 2, event_name: 'aa123bb')
        EventBus.publish('aa123bb', a: 1, b: 2)
      end

      it 'does not call the block when the event does not match' do
        expect(spy).to_not receive(:block_called)
        EventBus.publish('blah')
      end
    end

    context 'with a listener object' do
      before { EventBus.subscribe(listener) }

      it 'calls a listener method whose name matches the event name' do
        expect(listener).to receive(:handler).with(a: 2, b: 3, event_name: 'handler')
        EventBus.publish('handler', a: 2, b: 3)
      end

      it 'calls a listener method with symbol whose name matches the event name' do
        expect(listener).to receive(:handler).with(a: 2, b: 3, event_name: :handler)
        EventBus.publish(:handler, a: 2, b: 3)
      end

      it 'calls no method when there is no name match' do
        expect(listener).to_not receive(:handler)
        EventBus.publish('b_method')
      end

    end

    context 'when specifying the event name' do

      example 'a method or a block must be provided' do
        expect { EventBus.subscribe('blah', listener) }.to raise_exception(ArgumentError)
      end

      example 'a method AND a block cannot both be given' do
        expect { EventBus.subscribe('blah', listener, :handler) {|info| }}.to raise_exception(ArgumentError)
      end

      example 'a block must be provided when no method is supplied' do
        expect { EventBus.subscribe('blah') }.to raise_exception(ArgumentError)
      end

    end

    context 'when specifying a listener object' do

      example 'a method must not be given' do
        expect { EventBus.subscribe(listener, double) }.to raise_exception(ArgumentError)
      end

      example 'a block must not be given' do
        expect { EventBus.subscribe(listener) {|info| } }.to raise_exception(ArgumentError)
      end

    end

  end

  describe '.clear' do
    it 'removes all previous registrants' do
      EventBus.subscribe('aa123bb', listener, :handler)
      EventBus.clear
      expect(listener).to_not receive(:handler)
      EventBus.publish('aa123bb', {})
    end

  end

  context 'when calling several EventBus methods' do

    example 'clear() can be cascaded' do
      expect(EventBus.clear).to be == EventBus
    end

    example 'publish() can be cascaded' do
      expect(EventBus.publish('aa123bb', {})).to be == EventBus
    end

    example 'subscribe() can be cascaded' do
      expect(EventBus.subscribe('aa123bb', listener, :handler)).to be == EventBus
    end

    example 'with_temporary_subscriber() can be cascaded' do
      expect(EventBus.with_temporary_subscriber('aa123bb', listener, :handler) { }).to be == EventBus
    end
  end

end


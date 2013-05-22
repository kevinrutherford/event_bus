require 'spec_helper'

describe EventBus do
  let(:listener) { double(:listener) }

  before do
    EventBus.clear
    listener.stub(:handler) { }
  end

  describe 'publishing' do

    it 'accepts a string for the event name' do
      EventBus.subscribe(/aa123bb/, listener, :handler)
      EventBus.publish('aa123bb')
      listener.should have_received(:handler).with(event_name: 'aa123bb')
    end

    it 'accepts a symbol for the event name' do
      EventBus.subscribe(/abc_123/, listener, :handler)
      EventBus.publish(:abc_123)
      listener.should have_received(:handler).with(event_name: :abc_123)
    end

    it 'rejects any other type as the event name' do
      expect { EventBus.publish(123) }.to raise_error(ArgumentError)
    end

    it 'returns itself, to facilitate cascades' do
      EventBus.publish('aa123bb', {}).should == EventBus
    end

    it 'adds the event name to the payload' do
      EventBus.subscribe('aa123bb', listener, :handler)
      EventBus.publish('aa123bb', a: 56)
      listener.should have_received(:handler).with(event_name: 'aa123bb', a: 56)
    end

    it 'allows the payload to be omitted' do
      EventBus.subscribe('aa123bb', listener, :handler)
      EventBus.publish('aa123bb')
      listener.should have_received(:handler).with(event_name: 'aa123bb')
    end

  end

  describe 'publishing with errors' do
    let(:erroring_listener) { double(:erroring_listener) }
    let(:error_handler) { double(:error_handler) }

    before do
      erroring_listener.stub(:handler) { raise RuntimeError.new }
      error_handler.stub(:handle_error) {}
    end

    it 'sends the event to the second listener when the first errors' do
      EventBus.subscribe('aa123bb', erroring_listener, :handler)
      EventBus.subscribe('aa123bb', listener, :handler)

      EventBus.publish('aa123bb')
      listener.should have_received(:handler).with(event_name: 'aa123bb')
    end

    it 'calls the error handler on an error when the listener is an object' do
      EventBus.subscribe('aa123bb', erroring_listener, :handler)
      EventBus.on_error do |listener, full_payload|
        error_handler.handle_error listener, full_payload
      end

      EventBus.publish('aa123bb')

      error_handler.should have_received(:handle_error).with(erroring_listener, event_name: 'aa123bb')
    end

    it 'calls the error handler on an error when the listener is a block' do
      EventBus.subscribe('aa123bb') do |info|
        raise RuntimeError.new
      end

      EventBus.on_error do |listener, full_payload|
        error_handler.handle_error listener, full_payload
      end

      EventBus.publish('aa123bb')

      error_handler.should have_received(:handle_error).with(instance_of(Proc), event_name: 'aa123bb')
    end
  end

  describe 'subscribing' do

    it 'returns itself, to facilitate cascades' do
      EventBus.subscribe('aa123bb', listener, :handler).should == EventBus
    end

    context 'with a regex pattern' do
      it 'sends the event to a matching listener' do
        EventBus.subscribe(/123b/, listener, :handler)
        EventBus.publish('aa123bb', a: 1, b: 2)
        listener.should have_received(:handler).with(a: 1, b: 2, event_name: 'aa123bb')
      end

      it 'does not send the event to non-matching listeners' do
        EventBus.subscribe(/123a/, listener, :handler)
        EventBus.publish('aa123bb', a: 1, b: 2, event_name: 'aa123bb')
        listener.should_not have_received(:handler)
      end
    end

    context 'with a string pattern' do
      it 'sends the event to a matching listener' do
        EventBus.subscribe('aa123bb', listener, :handler)
        EventBus.publish('aa123bb', a: 1, b: 2)
        listener.should have_received(:handler).with(a: 1, b: 2, event_name: 'aa123bb')
      end

      it 'does not send the event to non-matching listeners' do
        EventBus.subscribe('blah', listener, :handler)
        EventBus.publish('aa123bb', a: 1, b: 2, event_name: 'aa123bb')
        listener.should_not have_received(:handler)
      end
    end

    context 'with a symbol pattern' do
      it 'sends the event to a matching listener' do
        EventBus.subscribe(:abc_123, listener, :handler)
        EventBus.publish(:abc_123, a: 1, b: 2)
        listener.should have_received(:handler).with(a: 1, b: 2, event_name: :abc_123)
      end

      it 'does not send the event to non-matching listeners' do
        EventBus.subscribe(:blah, listener, :handler)
        EventBus.publish('aa123bb', a: 1, b: 2, event_name: 'aa123bb')
        listener.should_not have_received(:handler)
      end
    end

    context 'with a listener method' do
      it 'will not accept a block too' do
        expect { EventBus.subscribe('blah', listener, :handler) {|info| }}.to raise_error(ArgumentError)
      end

      it 'expects a method name' do
        expect { EventBus.subscribe('blah', listener) }.to raise_error(ArgumentError)
      end
    end

    context 'with a block' do
      it 'requires a block when no listener method is supplied' do
        expect { EventBus.subscribe('blah') }.to raise_error(ArgumentError)
      end

      it 'calls the block when the event matches' do
        block_called = false
        EventBus.subscribe('aa123bb') do |info|
          block_called = true
          info.should == {a: 1, b: 2, event_name: 'aa123bb'}
        end
        EventBus.publish('aa123bb', a: 1, b: 2)
        block_called.should be_true
      end

      it 'does not call the block when the event does not match' do
        block_called = false
        EventBus.subscribe('blah') {|_| block_called = true }
        EventBus.publish('aa123bb')
        block_called.should be_false
      end
    end

    context 'with a listener object' do

      it 'calls a listener method whose name matches the event name' do
        EventBus.subscribe(listener)
        EventBus.publish(:handler.to_s, a: 2, b: 3)
        listener.should have_received(:handler).with(a: 2, b: 3, event_name: :handler.to_s)
      end

      it 'calls a listener method with symbol whose name matches the event name' do
        EventBus.subscribe(listener)
        EventBus.publish(:handler, a: 2, b: 3)
        listener.should have_received(:handler).with(a: 2, b: 3, event_name: :handler)
      end

      it 'calls no method when there is no name match' do
        EventBus.subscribe(listener)
        EventBus.publish('b_method')
        listener.should_not have_received(:handler)
      end

      it 'will not accept other arguments' do
        expect { EventBus.subscribe(listener, double) }.to raise_error(ArgumentError)
      end

      it 'will not accept a block' do
        expect { EventBus.subscribe(listener) {|info| }}.to raise_error(ArgumentError)
      end

    end

  end

  describe '.clear' do
    it 'removes all previous registrants' do
      EventBus.subscribe('aa123bb', listener, :handler)
      EventBus.clear
      EventBus.publish('aa123bb', {})
      listener.should_not have_received(:handler)
    end

    it 'returns itself, to facilitate cascades' do
      EventBus.clear.should == EventBus
    end
  end

end


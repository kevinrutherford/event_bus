require 'spec_helper'

describe EventBus do
  let(:listener) { double(:listener) }
  let(:event_name) { 'aa123bb' }
  let(:receiving_method) { :receiving_method_name }

  before do
    EventBus.clear
    listener.stub(receiving_method) { }
  end

  describe 'publishing' do

    it 'accepts a string for the event name' do
      EventBus.subscribe(/#{event_name}/, listener, receiving_method)
      EventBus.publish(event_name)
      listener.should have_received(receiving_method).with(event_name: event_name)
    end

    it 'accepts a symbol for the event name' do
      event_sym = :abc_123
      EventBus.subscribe(/#{event_sym}/, listener, receiving_method)
      EventBus.publish(event_sym)
      listener.should have_received(receiving_method).with(event_name: event_sym)
    end

    it 'rejects any other type as the event name' do
      expect { EventBus.publish(123) }.to raise_error(ArgumentError)
    end

    it 'returns itself, to facilitate cascades' do
      EventBus.publish(event_name, {}).should == EventBus
    end

    it 'adds the event name to the payload' do
      EventBus.subscribe(event_name, listener, receiving_method)
      EventBus.publish(event_name, a: 56)
      listener.should have_received(receiving_method).with(event_name: event_name, a: 56)
    end

    it 'allows the payload to be omitted' do
      EventBus.subscribe(event_name, listener, receiving_method)
      EventBus.publish(event_name)
      listener.should have_received(receiving_method).with(event_name: event_name)
    end

  end

  describe 'publishing with errors' do
    let(:erroring_listener) { double(:erroring_listener) }
    let(:error_handler) { double(:error_handler) }

    before do
      erroring_listener.stub(receiving_method) { raise RuntimeError.new }
      error_handler.stub(:handle_error) {}
    end

    it "sends the event to the second listner when the first errors" do
      EventBus.subscribe(event_name, erroring_listener, receiving_method)
      EventBus.subscribe(event_name, listener, receiving_method)

      EventBus.publish(event_name)
      listener.should have_received(receiving_method).with(event_name: event_name)
    end

    it "calls the error handler on an error when the listener is an object" do
      EventBus.subscribe(event_name, erroring_listener, receiving_method)
      EventBus.on_error do |listener, full_payload| 
        error_handler.handle_error listener, full_payload
      end

      EventBus.publish(event_name)

      error_handler.should have_received(:handle_error).with(erroring_listener, event_name: event_name)
    end

    it "calls the error handler on an error when the listener is a block" do
      EventBus.subscribe(event_name) do |info|
        raise RuntimeError.new
      end

      EventBus.on_error do |listener, full_payload| 
        error_handler.handle_error listener, full_payload
      end

      EventBus.publish(event_name)

      error_handler.should have_received(:handle_error).with(instance_of(Proc), event_name: event_name)
    end
  end

  describe 'subscribing' do

    it 'returns itself, to facilitate cascades' do
      EventBus.subscribe(event_name, listener, receiving_method).should == EventBus
    end

    context 'with a regex pattern' do
      it 'sends the event to a matching listener' do
        EventBus.subscribe(/123b/, listener, receiving_method)
        EventBus.publish(event_name, a: 1, b: 2)
        listener.should have_received(receiving_method).with(a: 1, b: 2, event_name: event_name)
      end

      it 'does not send the event to non-matching listeners' do
        EventBus.subscribe(/123a/, listener, receiving_method)
        EventBus.publish(event_name, a: 1, b: 2, event_name: event_name)
        listener.should_not have_received(receiving_method)
      end
    end

    context 'with a string pattern' do
      it 'sends the event to a matching listener' do
        EventBus.subscribe(event_name, listener, receiving_method)
        EventBus.publish(event_name, a: 1, b: 2)
        listener.should have_received(receiving_method).with(a: 1, b: 2, event_name: event_name)
      end

      it 'does not send the event to non-matching listeners' do
        EventBus.subscribe('blah', listener, receiving_method)
        EventBus.publish(event_name, a: 1, b: 2, event_name: event_name)
        listener.should_not have_received(receiving_method)
      end
    end

    context 'with a symbol pattern' do
      it 'sends the event to a matching listener' do
        event_name = :abc_123
        EventBus.subscribe(event_name, listener, receiving_method)
        EventBus.publish(event_name, a: 1, b: 2)
        listener.should have_received(receiving_method).with(a: 1, b: 2, event_name: event_name)
      end

      it 'does not send the event to non-matching listeners' do
        EventBus.subscribe(:blah, listener, receiving_method)
        EventBus.publish(event_name, a: 1, b: 2, event_name: event_name)
        listener.should_not have_received(receiving_method)
      end
    end

    context 'with a listener method' do
      it 'will not accept a block too' do
        expect { EventBus.subscribe('blah', listener, receiving_method) {|info| }}.to raise_error(ArgumentError)
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
        EventBus.subscribe(event_name) do |info|
          block_called = true
          info.should == {a: 1, b: 2, event_name: event_name}
        end
        EventBus.publish(event_name, a: 1, b: 2)
        block_called.should be_true
      end

      it 'does not call the block when the event does not match' do
        block_called = false
        EventBus.subscribe('blah') {|_| block_called = true }
        EventBus.publish(event_name)
        block_called.should be_false
      end
    end

    context 'with a listener object' do

      it 'calls a listener method whose name matches the event name' do
        EventBus.subscribe(listener)
        EventBus.publish(receiving_method.to_s, a: 2, b: 3)
        listener.should have_received(receiving_method).with(a: 2, b: 3, event_name: receiving_method.to_s)
      end

      it 'calls a listener method with symbol whose name matches the event name' do
        EventBus.subscribe(listener)
        EventBus.publish(receiving_method, a: 2, b: 3)
        listener.should have_received(receiving_method).with(a: 2, b: 3, event_name: receiving_method)
      end

      it 'calls no method when there is no name match' do
        EventBus.subscribe(listener)
        EventBus.publish('b_method')
        listener.should_not have_received(receiving_method)
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
      EventBus.subscribe(event_name, listener, receiving_method)
      EventBus.clear
      EventBus.publish(event_name, {})
      listener.should_not have_received(receiving_method)
    end

    it 'returns itself, to facilitate cascades' do
      EventBus.clear.should == EventBus
    end
  end

end


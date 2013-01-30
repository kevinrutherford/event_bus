require 'spec_helper'

describe EventBus do
  let(:listener) { double(:listener) }
  let(:event_name) { 'aa123bb' }
  let(:receiving_method) { :receiving_method_name }

  before do
    EventBus.clear
  end

  describe '.publish' do

    it 'returns itself, to facilitate cascades' do
      EventBus.publish(event_name, {}).should == EventBus
    end

    it 'passes the event name in the details hash' do
      EventBus.subscribe(event_name, listener, receiving_method)
      listener.should_receive(receiving_method).with(:event_name => event_name)
      EventBus.publish(event_name, {})
    end

    it 'allows the details hash to be omitted' do
      EventBus.subscribe(event_name, listener, receiving_method)
      listener.should_receive(receiving_method).with(:event_name => event_name)
      EventBus.publish(event_name)
    end

  end

  describe '.subscribe' do

    it 'returns itself, to facilitate cascades' do
      EventBus.subscribe(event_name, listener, receiving_method).should == EventBus
    end

    context 'accepts a string event name' do
      it 'sends the event to a matching listener' do
        EventBus.subscribe(event_name, listener, receiving_method)
        listener.should_receive(receiving_method).with(:a => 1, :b => 2, :event_name => event_name)
        EventBus.publish(event_name, :a => 1, :b => 2)
      end

      it 'does not send the event to non-matching listeners' do
        EventBus.subscribe('blah', listener, receiving_method)
        listener.should_not_receive(receiving_method)
        EventBus.publish(event_name, :a => 1, :b => 2, :event_name => event_name)
      end
    end

    context 'accepts a regex event name' do
      it 'sends the event to a matching listener' do
        EventBus.subscribe(/123b/, listener, receiving_method)
        listener.should_receive(receiving_method).with(:a => 1, :b => 2, :event_name => event_name)
        EventBus.publish(event_name, :a => 1, :b => 2)
      end

      it 'does not send the event to non-matching listeners' do
        EventBus.subscribe(/123a/, listener, receiving_method)
        listener.should_not_receive(receiving_method)
        EventBus.publish(event_name, :a => 1, :b => 2, :event_name => event_name)
      end
    end

    context 'listener variant' do
      it 'will not accept a block too' do
        expect { EventBus.subscribe('blah', listener, receiving_method) {|info| }}.to raise_error(ArgumentError)
      end

      it 'expects a method name' do
        expect { EventBus.subscribe('blah', listener)}.to raise_error(ArgumentError)
      end
    end

    context 'block variant' do
      it 'requires a block when no listener method is supplied' do
        expect { EventBus.subscribe('blah')}.to raise_error(ArgumentError)
      end

      it 'calls the block when the event matches' do
        block_called = false
        EventBus.subscribe(event_name) do |info|
          block_called = true
          info.should == {:a => 1, :b => 2, :event_name => event_name}
        end
        EventBus.publish(event_name, :a => 1, :b => 2)
        block_called.should be_true
      end

      it 'does not call the block when the event does not match' do
        block_called = false
        EventBus.subscribe('blah') {|_| block_called = true }
        EventBus.publish(event_name, :a => 1, :b => 2)
        block_called.should be_false
      end
    end

  end

  describe '.clear' do
    it 'removes all previous registrants' do
      EventBus.subscribe(event_name, listener, receiving_method)
      EventBus.clear
      listener.should_not_receive(receiving_method)
      EventBus.publish(event_name, {})
    end

    it 'returns itself, to facilitate cascades' do
      EventBus.clear.should == EventBus
    end
  end

end


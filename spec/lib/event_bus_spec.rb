require 'spec_helper'

describe EventBus do
  let(:listener) { double(:listener) }
  let(:event_name) { 'aa123bb' }
  let(:receiving_method) { :receiving_method_name }

  before do
    EventBus.clear
  end

  describe '.announce' do

    it 'returns itself, to facilitate cascades' do
      EventBus.announce(event_name, {}).should == EventBus
    end

    it 'passes the event name in the details hash' do
      EventBus.listen_for(event_name, listener, receiving_method)
      listener.should_receive(receiving_method).with({:event_name => event_name})
      EventBus.announce(event_name, {}).should == EventBus
    end

    context 'when the listener is specific about the event name' do
      it 'sends the event to the listener' do
        EventBus.listen_for(event_name, listener, receiving_method)
        listener.should_receive(receiving_method).with({:a => 1, :b => 2, :event_name => event_name})
        EventBus.announce(event_name, {:a => 1, :b => 2})
      end
    end

    context 'when the listener uses a regex that matches' do
      it 'sends the event to the listener' do
        EventBus.listen_for(/123b/, listener, receiving_method)
        listener.should_receive(receiving_method).with({:a => 1, :b => 2, :event_name => event_name})
        EventBus.announce(event_name, {:a => 1, :b => 2})
      end
    end

    context 'when the listener listens for a different event' do
      it 'does not send the event to the listener' do
        EventBus.listen_for('blah', listener, receiving_method)
        listener.should_not_receive(receiving_method)
        EventBus.announce(event_name, {:a => 1, :b => 2, :event_name => event_name})
      end
    end

    context 'when the listener listens for a non-matching regex' do
      it 'does not send the event to the listener' do
        EventBus.listen_for(/123a/, listener, receiving_method)
        listener.should_not_receive(receiving_method)
        EventBus.announce(event_name, {:a => 1, :b => 2, :event_name => event_name})
      end
    end

  end

  describe '.clear' do
    it 'sends no event to previous registrants' do
      EventBus.listen_for(event_name, listener, receiving_method)
      EventBus.clear
      listener.should_not_receive(receiving_method)
      EventBus.announce(event_name, {})
    end

    it 'returns itself, to facilitate cascades' do
      EventBus.clear.should == EventBus
    end
  end

end


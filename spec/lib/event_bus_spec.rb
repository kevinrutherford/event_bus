require 'spec_helper'

describe EventBus do
  let(:listener) { double(:listener) }
  let(:event_name) { 'aa123bb' }
  let(:receiver) { :receiving_method }

  before do
    EventBus.listen_for(event_name, listener, receiver)
  end

  describe '.announce' do

    context 'with no payload' do
      it 'sends an event to a listener' do
        listener.should_receive(receiver)
        EventBus.announce(event_name, {})
      end
    end
  end

  describe '.clear' do
    it 'sends no event to previous registrants' do
      EventBus.clear
      listener.should_not_receive(receiver)
      EventBus.announce(event_name, {})
    end
  end

end


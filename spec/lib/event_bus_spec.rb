require 'spec_helper'

describe EventBus do
  let(:listener) { double(:listener) }
  let(:event_name) { 'aa123bb' }
  let(:receiving_method) { :receiving_method_name }

  before do
    EventBus.clear
    EventBus.listen_for(event_name, listener, receiving_method)
  end

  describe '.announce' do

    context 'with no payload' do
      it 'sends an event to a listener' do
        listener.should_receive(receiving_method)
        EventBus.announce(event_name, {})
      end
    end
  end

  describe '.clear' do
    it 'sends no event to previous registrants' do
      EventBus.clear
      listener.should_not_receive(receiving_method)
      EventBus.announce(event_name, {})
    end

    it 'returns itself, to facilitate cascades' do
      EventBus.clear.should == EventBus
    end
  end

end


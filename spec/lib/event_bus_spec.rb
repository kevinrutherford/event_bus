require 'spec_helper'

describe EventBus do

  describe '.announce' do

    context 'with no payload' do
      it 'sends an event to a listener' do
        listener = double(:listener)
        listener.should_receive(:fred)
        EventBus.listen_for('aaa', listener, :fred)
        EventBus.announce('aaa', {})
      end
    end
  end

end


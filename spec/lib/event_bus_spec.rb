require 'spec_helper'

describe EventBus do
  let(:listener) { double(:listener, handler: true) }

  before do
    EventBus.clear
  end

  describe 'publishing' do

    context 'accepts a string for the event name' do
      Given { EventBus.subscribe(/aa123bb/, listener, :handler) }
      When { EventBus.publish('aa123bb') }
      Then { listener.should have_received(:handler).with(event_name: 'aa123bb') }
    end

    context 'accepts a symbol for the event name' do
      Given { EventBus.subscribe(/aa123bb/, listener, :handler) }
      When { EventBus.publish(:aa123bb) }
      Then { listener.should have_received(:handler).with(event_name: :aa123bb) }
    end

    context 'rejects any other type as the event name' do
      When(:result) { EventBus.publish(123) }
      Then { result.should have_failed(ArgumentError) }
    end

    context 'adds the event name to the payload' do
      Given { EventBus.subscribe('aa123bb', listener, :handler) }
      When { EventBus.publish('aa123bb', a: 56) }
      Then { listener.should have_received(:handler).with(event_name: 'aa123bb', a: 56) }
    end

    context 'allows the payload to be omitted' do
      Given { EventBus.subscribe('aa123bb', listener, :handler) }
      When { EventBus.publish('aa123bb') }
      Then { listener.should have_received(:handler).with(event_name: 'aa123bb') }
    end

  end

  describe 'publishing with errors' do
    let(:erroring_listener) { double(:erroring_listener) }
    let(:error_handler) { double(:error_handler, handle_error: true) }

    before do
      erroring_listener.stub(:handler) { raise RuntimeError.new }
    end

    context 'sends the event to the second listener when the first errors' do
      Given { EventBus.subscribe('aa123bb', erroring_listener, :handler) }
      Given { EventBus.subscribe('aa123bb', listener, :handler) }
      When { EventBus.publish('aa123bb') }
      Then { listener.should have_received(:handler).with(event_name: 'aa123bb') }
    end

    context 'calls the error handler on an error when the listener is an object' do
      Given { EventBus.subscribe('aa123bb', erroring_listener, :handler) }
      Given { EventBus.on_error do |listener, full_payload|
        error_handler.handle_error listener, full_payload
      end }

      When { EventBus.publish('aa123bb') }

      Then { error_handler.should have_received(:handle_error).with(erroring_listener, event_name: 'aa123bb') }
    end

    context 'calls the error handler on an error when the listener is a block' do
      Given { EventBus.subscribe('aa123bb') {|info| raise RuntimeError.new } }

      Given { EventBus.on_error do |listener, full_payload|
        error_handler.handle_error listener, full_payload
      end }

      When { EventBus.publish('aa123bb') }

      Then { error_handler.should have_received(:handle_error).with(instance_of(Proc), event_name: 'aa123bb') }
    end
  end

  describe 'subscribing' do

    context 'with a regex pattern' do
      context 'sends the event to a matching listener' do
        Given { EventBus.subscribe(/123b/, listener, :handler) }
        When { EventBus.publish('aa123bb', a: 1, b: 2) }
        Then { listener.should have_received(:handler).with(a: 1, b: 2, event_name: 'aa123bb') }
      end

      context 'does not send the event to non-matching listeners' do
        Given { EventBus.subscribe(/123a/, listener, :handler) }
        When { EventBus.publish('aa123bb', a: 1, b: 2, event_name: 'aa123bb') }
        Then { listener.should_not have_received(:handler) }
      end
    end

    context 'with a string pattern' do
      context 'sends the event to a matching listener' do
        Given { EventBus.subscribe('aa123bb', listener, :handler) }
        When { EventBus.publish('aa123bb', a: 1, b: 2) }
        Then { listener.should have_received(:handler).with(a: 1, b: 2, event_name: 'aa123bb') }
      end

      context 'does not send the event to non-matching listeners' do
        Given { EventBus.subscribe('blah', listener, :handler) }
        When { EventBus.publish('aa123bb', a: 1, b: 2, event_name: 'aa123bb') }
        Then { listener.should_not have_received(:handler) }
      end
    end

    context 'with a symbol pattern' do
      context 'sends the event to a matching listener' do
        Given { EventBus.subscribe(:aa123bb, listener, :handler) }
        When { EventBus.publish(:aa123bb, a: 1, b: 2) }
        Then { listener.should have_received(:handler).with(a: 1, b: 2, event_name: :aa123bb) }
      end

      context 'does not send the event to non-matching listeners' do
        Given { EventBus.subscribe(:blah, listener, :handler) }
        When { EventBus.publish('aa123bb', a: 1, b: 2, event_name: 'aa123bb') }
        Then { listener.should_not have_received(:handler) }
      end
    end

    context 'with a listener method' do
      context 'will not accept a block too' do
        When(:result) { EventBus.subscribe('blah', listener, :handler) {|info| }}
        Then { result.should have_failed(ArgumentError) }
      end

      context 'expects a method name' do
        When(:result) { EventBus.subscribe('blah', listener) }
        Then { result.should have_failed(ArgumentError) }
      end
    end

    context 'with a block' do
      context 'requires a block when no listener method is supplied' do
        When(:result) { EventBus.subscribe('blah') }
        Then { result.should have_failed(ArgumentError) }
      end

      context 'calls the block when the event matches' do
        Given(:spy) { double(:spy, block_called: nil) }
        Given {
          EventBus.subscribe('aa123bb') {|info| spy.block_called(info) }
        }
        When { EventBus.publish('aa123bb', a: 1, b: 2) }
        Then { spy.should have_received(:block_called).with(a: 1, b: 2, event_name: 'aa123bb') }
      end

      context 'does not call the block when the event does not match' do
        Given(:spy) { double(:spy, block_called: nil) }
        Given {
          EventBus.subscribe('aa123bb') {|info| spy.block_called(info) }
        }
        When { EventBus.publish('blah', a: 1, b: 2) }
        Then { spy.should_not have_received(:block_called) }
      end
    end

    context 'with a listener object' do
      Given { EventBus.subscribe(listener) }

      context 'calls a listener method whose name matches the event name' do
        When { EventBus.publish('handler', a: 2, b: 3) }
        Then { listener.should have_received(:handler).with(a: 2, b: 3, event_name: 'handler') }
      end

      context 'calls a listener method with symbol whose name matches the event name' do
        When { EventBus.publish(:handler, a: 2, b: 3) }
        Then { listener.should have_received(:handler).with(a: 2, b: 3, event_name: :handler) }
      end

      context 'calls no method when there is no name match' do
        When { EventBus.publish('b_method') }
        Then { listener.should_not have_received(:handler) }
      end

    end

    context 'subscribing with an object and a method' do
      When(:subscribe) { EventBus.subscribe(listener, double) }
      Then { subscribe.should have_failed(ArgumentError) }
    end

    context 'subscribing with an object and a block' do
      When(:subscribe) { EventBus.subscribe(listener) {|info| } }
      Then { subscribe.should have_failed(ArgumentError) }
    end

  end

  describe '.clear' do
    context 'removes all previous registrants' do
      Given { EventBus.subscribe('aa123bb', listener, :handler) }
      Given { EventBus.clear }
      When { EventBus.publish('aa123bb', {}) }
      Then { listener.should_not have_received(:handler) }
    end

  end

  context 'EventBus methods cascade' do

    context 'clear' do
      When(:result) { EventBus.clear }
      Then { result.should == EventBus }
    end

    context 'publish' do
      When(:result) { EventBus.publish('aa123bb', {}) }
      Then { result.should == EventBus }
    end

    context 'subscribe' do
      When(:result) { EventBus.subscribe('aa123bb', listener, :handler) }
      Then { result.should == EventBus }
    end

  end

end


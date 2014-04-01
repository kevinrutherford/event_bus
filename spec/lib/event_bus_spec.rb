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

  describe 'bg_publishing' do

    context 'accepts a string for the event name' do
      Given { EventBus.subscribe(/aa123bb/, listener, :handler) }
      When { EventBus.bg_publish('aa123bb') }
      Then { listener.should have_received(:handler).with(event_name: 'aa123bb') }
    end

    context 'accepts a string for the event name (originaly sympol)' do
      Given { EventBus.subscribe(/aa123bb/, listener, :handler) }
      When { EventBus.bg_publish(:aa123bb) }
      Then { listener.should have_received(:handler).with(event_name: 'aa123bb') }
    end

    context 'rejects any other type as the event name' do
      When(:result) { EventBus.bg_publish(123) }
      Then { result.should have_failed(ArgumentError) }
    end

    context 'adds the event name to the payload' do
      Given { EventBus.subscribe('aa123bb', listener, :handler) }
      When { EventBus.bg_publish('aa123bb', a: 56) }
      Then { listener.should have_received(:handler).with(event_name: 'aa123bb', 'a' => 56) }
    end

    context 'convert payload symbol keys to strings' do
      Given { EventBus.subscribe('aa123bb', listener, :handler) }
      When { EventBus.bg_publish('aa123bb', a: 56) }
      Then { listener.should have_received(:handler).with(event_name: 'aa123bb', 'a' => 56) }
    end

    context 'allows the payload to be omitted' do
      Given { EventBus.subscribe('aa123bb', listener, :handler) }
      When { EventBus.bg_publish('aa123bb') }
      Then { listener.should have_received(:handler).with(event_name: 'aa123bb') }
    end

  end

  describe 'publishing with errors' do
    Given(:error) { RuntimeError.new }
    Given(:erroring_listener) { double(:erroring_listener) }
    Given(:error_handler) { double(:error_handler, handle_error: true) }
    Given { erroring_listener.stub(:handler) { raise error } }

    context 'sends the event to the second listener when the first errors' do
      Given { EventBus.subscribe('aa123bb', erroring_listener, :handler) }
      Given { EventBus.subscribe('aa123bb', listener, :handler) }
      When { EventBus.publish('aa123bb') }
      Then { listener.should have_received(:handler).with(event_name: 'aa123bb') }
    end

    context 'with an error handler' do
      Given { EventBus.on_error do |listener, payload|
        error_handler.handle_error(listener, payload)
      end }

      context 'when the listener is an object' do
        Given { EventBus.subscribe('aa123bb', erroring_listener, :handler) }
        When { EventBus.publish('aa123bb') }
        Then { error_handler.should have_received(:handle_error).with(erroring_listener, event_name: 'aa123bb', error: error ) }
      end

      context 'when the listener is a block' do
        Given { EventBus.subscribe('aa123bb') {|info| raise error } }
        When { EventBus.publish('aa123bb') }
        Then { error_handler.should have_received(:handle_error).with(instance_of(Proc), event_name: 'aa123bb', error: error) }
      end

    end

  end

  describe 'bg_publishing with errors' do
    Given(:error) { RuntimeError.new }
    Given(:erroring_listener) { double(:erroring_listener) }
    Given(:error_handler) { double(:error_handler, handle_error: true) }
    Given { erroring_listener.stub(:handler) { raise error } }

    context 'sends the event to the second listener when the first errors' do
      Given { EventBus.subscribe('aa123bb', erroring_listener, :handler) }
      Given { EventBus.subscribe('aa123bb', listener, :handler) }
      When { EventBus.bg_publish('aa123bb') }
      Then { listener.should have_received(:handler).with(event_name: 'aa123bb') }
    end

    context 'with an error handler' do
      Given { EventBus.on_error do |listener, payload|
        error_handler.handle_error(listener, payload)
      end }

      context 'when the listener is an object' do
        Given { EventBus.subscribe('aa123bb', erroring_listener, :handler) }
        When { EventBus.bg_publish('aa123bb') }
        Then { error_handler.should have_received(:handle_error).with(erroring_listener, event_name: 'aa123bb', error: error ) }
      end

      context 'when the listener is a block' do
        Given { EventBus.subscribe('aa123bb') {|info| raise error } }
        When { EventBus.bg_publish('aa123bb') }
        Then { error_handler.should have_received(:handle_error).with(instance_of(Proc), event_name: 'aa123bb', error: error) }
      end

    end

  end

  describe 'subscribing' do

    context 'publishing' do
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

      context 'subscribing a block' do
        Given(:spy) { double(:spy, block_called: nil) }
        Given {
          EventBus.subscribe('aa123bb') {|info| spy.block_called(info) }
        }

        context 'calls the block when the event matches' do
          When { EventBus.publish('aa123bb', a: 1, b: 2) }
          Then { spy.should have_received(:block_called).with(a: 1, b: 2, event_name: 'aa123bb') }
        end

        context 'does not call the block when the event does not match' do
          When { EventBus.publish('blah') }
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


    end

    context 'bg_publishing' do
      context 'with a regex pattern' do
        context 'sends the event to a matching listener' do
          Given { EventBus.subscribe(/123b/, listener, :handler) }
          When { EventBus.bg_publish('aa123bb', a: 1, b: 2) }
          Then { listener.should have_received(:handler).with('a' => 1, 'b' => 2, event_name: 'aa123bb') }
        end

        context 'does not send the event to non-matching listeners' do
          Given { EventBus.subscribe(/123a/, listener, :handler) }
          When { EventBus.bg_publish('aa123bb', 'a' => 1, 'b' => 2, event_name: 'aa123bb') }
          Then { listener.should_not have_received(:handler) }
        end
      end

      context 'with a string pattern' do
        context 'sends the event to a matching listener' do
          Given { EventBus.subscribe('aa123bb', listener, :handler) }
          When { EventBus.bg_publish('aa123bb', a: 1, b: 2) }
          Then { listener.should have_received(:handler).with('a' => 1, 'b' => 2, event_name: 'aa123bb') }
        end

        context 'does not send the event to non-matching listeners' do
          Given { EventBus.subscribe('blah', listener, :handler) }
          When { EventBus.bg_publish('aa123bb', a: 1, b: 2, event_name: 'aa123bb') }
          Then { listener.should_not have_received(:handler) }
        end
      end

      context 'with a symbol pattern' do
        context 'sends the event to a matching listener' do
          Given { EventBus.subscribe(:aa123bb, listener, :handler) }
          When { EventBus.bg_publish(:aa123bb, a: 1, b: 2) }
          Then { listener.should have_received(:handler).with('a' => 1, 'b' => 2, event_name: 'aa123bb') }
        end

        context 'does not send the event to non-matching listeners' do
          Given { EventBus.subscribe(:blah, listener, :handler) }
          When { EventBus.bg_publish('aa123bb', a: 1, b: 2, event_name: 'aa123bb') }
          Then { listener.should_not have_received(:handler) }
        end
      end

      context 'subscribing a block' do
        Given(:spy) { double(:spy, block_called: nil) }
        Given {
          EventBus.subscribe('aa123bb') {|info| spy.block_called(info) }
        }

        context 'calls the block when the event matches' do
          When { EventBus.bg_publish('aa123bb', a: 1, b: 2) }
          Then { spy.should have_received(:block_called).with('a' => 1, 'b' => 2, event_name: 'aa123bb') }
        end

        context 'does not call the block when the event does not match' do
          When { EventBus.bg_publish('blah') }
          Then { spy.should_not have_received(:block_called) }
        end
      end

      context 'with a listener object' do
        Given { EventBus.subscribe(listener) }

        context 'calls a listener method whose name matches the event name' do
          When { EventBus.bg_publish('handler', a: 2, b: 3) }
          Then { listener.should have_received(:handler).with('a' => 2, 'b' => 3, event_name: 'handler') }
        end

        context 'calls a listener method with symbol whose name matches the event name' do
          When { EventBus.bg_publish(:handler, a: 2, b: 3) }
          Then { listener.should have_received(:handler).with('a' =>2, 'b' => 3, event_name: 'handler') }
        end

        context 'calls no method when there is no name match' do
          When { EventBus.bg_publish('b_method') }
          Then { listener.should_not have_received(:handler) }
        end
      end

    end

    context 'when called incorrectly' do

      context 'when specifying the event name' do

        context 'must provide a method or a block' do
          When(:subscribe) { EventBus.subscribe('blah', listener) }
          Then { subscribe.should have_failed(ArgumentError) }
        end

        context 'cannot provide a method AND a block' do
          When(:subscribe) { EventBus.subscribe('blah', listener, :handler) {|info| }}
          Then { subscribe.should have_failed(ArgumentError) }
        end

        context 'must provide a block when no method is supplied' do
          When(:subscribe) { EventBus.subscribe('blah') }
          Then { subscribe.should have_failed(ArgumentError) }
        end

      end

      context 'when specifying a listener object' do

        context 'when a method is also provided' do
          When(:subscribe) { EventBus.subscribe(listener, double) }
          Then { subscribe.should have_failed(ArgumentError) }
        end

        context 'when a block is also provided' do
          When(:subscribe) { EventBus.subscribe(listener) {|info| } }
          Then { subscribe.should have_failed(ArgumentError) }
        end

      end

    end

  end

  describe '.clear' do
    context 'directly' do
      context 'removes all previous registrants' do
        Given { EventBus.subscribe('aa123bb', listener, :handler) }
        Given { EventBus.clear }
        When { EventBus.publish('aa123bb', {}) }
        Then { listener.should_not have_received(:handler) }
      end
    end

    context 'background' do
      context 'removes all previous registrants' do
        Given { EventBus.subscribe('aa123bb', listener, :handler) }
        Given { EventBus.clear }
        When { EventBus.bg_publish('aa123bb', {}) }
        Then { listener.should_not have_received(:handler) }
      end
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

    context 'bg_publish' do
      When(:result) { EventBus.bg_publish('aa123bb', {}) }
      Then { result.should == EventBus }
    end

    context 'subscribe' do
      When(:result) { EventBus.subscribe('aa123bb', listener, :handler) }
      Then { result.should == EventBus }
    end

  end

end


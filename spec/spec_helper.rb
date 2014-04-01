require 'rubygems'
require 'bundler/setup'
require 'simplecov'
require 'rspec-spies'
require 'rspec-given'
require 'sidekiq'
require 'sidekiq/testing'

Sidekiq::Testing.inline!
SimpleCov.start

require 'event_bus'

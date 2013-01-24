Gem::Specification.new do |s|
  s.name        = 'event_bus'
  s.version     = '0.0.2'
  s.date        = '2013-01-21'
  s.summary     = 'A simple pubsub event bus for Ruby applications'
  s.description = 'event_bus provides support for application-wide events, without coupling the publishing and subscribing objects or classes to each other'
  s.authors     = ['Kevin Rutherford']
  s.email       = 'kevin@rutherford-software.com'
  s.homepage    = 'http://github.com/kevinrutherford/event_bus'

  s.add_development_dependency 'rake', '~> 0.9.2'
  s.add_development_dependency 'rspec', '~> 2.12'
  s.add_development_dependency 'simplecov'

  s.files          = FileList['lib/**/*.rb', '[A-Z]*', 'spec/**/*'].to_a
  s.test_files     = `git ls-files -- spec`.split("\n")
  s.require_path   = 'lib'

end


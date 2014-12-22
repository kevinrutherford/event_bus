Gem::Specification.new do |s|
  s.name        = 'event_bus'
  s.version     = '1.0.0'
  s.date        = '2013-04-19'
  s.summary     = 'A simple pubsub event bus for Ruby applications'
  s.description = 'event_bus provides support for application-wide events, without coupling the publishing and subscribing objects or classes to each other'
  s.authors     = ['Kevin Rutherford']
  s.email       = 'kevin@rutherford-software.com'
  s.homepage    = 'http://github.com/kevinrutherford/event_bus'

  s.add_development_dependency 'json'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec', '~> 2.12'
  s.add_development_dependency 'rspec-given'
  s.add_development_dependency 'rspec-spies'

  s.files          = `git ls-files -- lib spec [A-Z]* .rspec .yardopts`.split("\n")
  s.test_files     = `git ls-files -- spec`.split("\n")
  s.require_path   = 'lib'

end


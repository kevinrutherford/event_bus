Gem::Specification.new do |s|
  s.name        = 'event_bus'
  s.version     = '1.1.0'
  s.date        = '2014-04-01'
  s.summary     = 'A simple pubsub event bus for Ruby applications with sidekiq background support'
  s.description = 'event_bus provides support for application-wide events, without coupling the publishing and subscribing objects or classes to each other'
  s.authors     = ['Kevin Rutherford', 'Ahmed Abdel Razzak']
  s.email       = ['kevin@rutherford-software.com', 'eng.abdelrazzak@gmail.com']
  s.homepage    = 'http://github.com/kevinrutherford/event_bus'

  s.add_development_dependency 'rake', '~> 10.0.1'
  s.add_development_dependency 'rspec', '~> 2.12'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'sidekiq'

  s.files          = `git ls-files -- lib spec [A-Z]* .rspec .yardopts`.split("\n")
  s.test_files     = `git ls-files -- spec`.split("\n")
  s.require_path   = 'lib'

end


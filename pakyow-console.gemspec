version = File.read(File.expand_path("../VERSION", __FILE__)).strip

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'pakyow-console'
  s.version     = version
  s.summary     = 'pakyow-console'
  s.description = "pakyow-console"
  s.license     = 'LGPL-3.0'

  s.required_ruby_version     = '>= 2.0.0'

  s.authors           = ['Bryan Powell']
  s.email             = 'bryan@metabahn.com'
  s.homepage          = 'http://pakyow.org'

  s.files        = Dir['README.md', 'LICENSE', 'lib/**/*']
  s.require_path = 'lib'

  s.add_dependency('pakyow', '> 0.9')
  s.add_dependency('pakyow-slim', '~> 0.2')
  s.add_dependency('sequel', '~> 4.25')
  s.add_dependency('pg', '~> 0.18')
  s.add_dependency('httparty', '~> 0.13')
  s.add_dependency('websocket-client-simple', '~> 0.2')
  s.add_dependency('inflecto', '~> 0.0')
  s.add_dependency('platform-api', '~> 0.3')
  s.add_dependency('image_size', '~> 1.4')
  s.add_dependency('mini_magick', '~> 4.2')
  s.add_dependency('bcrypt', '~> 3.1')
  s.add_dependency('celluloid', '~> 0.17')
end

version = File.read(File.expand_path("../VERSION", __FILE__)).strip

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'pakyow-console'
  s.version     = version
  s.summary     = 'pakyow-console'
  s.description = "pakyow-console"
  s.license     = 'MIT'

  s.required_ruby_version     = '>= 2.0.0'

  s.authors           = ['Bryan Powell']
  s.email             = 'bryan@metabahn.com'
  s.homepage          = 'http://pakyow.org'

  s.files        = Dir['README.md', 'LICENSE', 'lib/**/*']
  s.require_path = 'lib'

  s.add_dependency('pakyow', '> 0.9')
  s.add_dependency('pakyow-slim')
  s.add_dependency('sequel')
  s.add_dependency('pg')
  s.add_dependency('httparty')
  s.add_dependency('websocket-client-simple')
  s.add_dependency('inflecto')
  s.add_dependency('platform-api')
  s.add_dependency('image_size')
  s.add_dependency('mini_magick')
  s.add_dependency('bcrypt')
end

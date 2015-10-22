require File.expand_path('../lib/version', __FILE__)

Gem::Specification.new do |spec|
  spec.name                   = 'pakyow-console'
  spec.summary                = 'Pakyow Console'
  spec.description            = 'Web Console for Pakyow'
  spec.authors                = ['Bryan Powell']
  spec.email                  = 'bryan@metabahn.com'
  spec.homepage               = 'http://pakyow.org'
  spec.version                = Pakyow::Console::VERSION
  spec.require_path           = 'lib'
  spec.files                  = Dir['CHANGELOG.md', 'README.md', 'LICENSE', 'lib/**/*']
  spec.license                = 'LGPL-3.0'
  spec.required_ruby_version  = '>= 2.0.0'

  spec.add_dependency('pakyow', '> 0.9')
  spec.add_dependency('pakyow-slim', '~> 1.0')
  spec.add_dependency('sequel', '~> 4.25')
  spec.add_dependency('pg', '~> 0.18')
  spec.add_dependency('httparty', '~> 0.13')
  spec.add_dependency('websocket-client-simple', '~> 0.2')
  spec.add_dependency('inflecto', '~> 0.0')
  spec.add_dependency('platform-api', '~> 0.3')
  spec.add_dependency('image_size', '~> 1.4')
  spec.add_dependency('mini_magick', '~> 4.2')
  spec.add_dependency('bcrypt', '~> 3.1')
end

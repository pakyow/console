require '/Users/bryanp/code/pakyow/libs/pakyow/pakyow-support/lib/pakyow-support'
require '/Users/bryanp/code/pakyow/libs/pakyow/pakyow-core/lib/pakyow-core'
require '/Users/bryanp/code/pakyow/libs/pakyow/pakyow-presenter/lib/pakyow-presenter'

require 'pakyow-slim'

require 'sass/plugin/compiler'

require 'sequel'
Sequel::Model.plugin :timestamps, update_on_create: true

CONSOLE_ROOT = File.expand_path('../', __FILE__)

#TODO need to be smarter about view reloading in development by keeping up with changed views
# it's currently taking a 5ms response to a 400ms one; might also be worth doing a performance audit
Pakyow::App.config.presenter.view_stores[:console] = [File.join(CONSOLE_ROOT, 'views')]
Pakyow::App.config.app.resources[:console] = File.join(CONSOLE_ROOT, 'resources')

module Sass
  module Plugin
    #HACK this fixes some sass bug
    def self.checked_for_updates=(*args); end
  end
end

module Pakyow
  module Console
    def self.sass
      @sass ||= Sass::Plugin::Compiler.new
    end

    def self.loader
      @loader ||= Pakyow::Loader.new
    end

    def self.load_paths
      @load_paths ||= []
    end

    def self.imports
      @imports ||= []
    end

    def self.add_load_path(path)
      load_paths << path
    end

    def self.add_import(path)
      imports << Sass::Script::String.new(path)
    end

    def self.boot_plugins
      PluginRegistry.boot
    end
  end
end

require_relative 'data_type'
require_relative 'panel'
require_relative 'plugin'
require_relative 'route'

require_relative 'registries/data_type_registry'
require_relative 'registries/panel_registry'
require_relative 'registries/plugin_registry'
require_relative 'registries/route_registry'

require_relative 'plugins/core_plugin'

require '/Users/bryanp/code/pakyow/libs/pakyow-console-users/lib/pakyow-console-users'
require '/Users/bryanp/code/pakyow/libs/pakyow-console-release/lib/pakyow-console-release'

app_path = File.join(CONSOLE_ROOT, 'app')
res_path = File.join(CONSOLE_ROOT, 'resources', 'console')

Pakyow::Console.sass.add_template_location(File.join(res_path, 'scss'), File.join(res_path, 'styles'))
Pakyow::Console.add_load_path(app_path)

CLOSING_HEAD_REGEX = /<\/head>/m
CLOSING_BODY_REGEX = /<\/body>/m

Pakyow::App.after :init do
  @context = AppContext.new
  @socket ||= WebSocketClient.new(self, platform_client, platform_info)
end

Pakyow::App.after :process do
  if req.path_parts[0] != 'console' && @presenter.presented? && platform?
    view = ViewContext.new(View.new(File.open(File.join(CONSOLE_ROOT, 'views', 'console', '_toolbar.slim')).read, format: :slim), self)
    setup_toolbar(view)

    console_css = '<link href="/console/styles/console-toolbar.css" rel="stylesheet" type="text/css">'
    font_css = '<link href="http://fonts.googleapis.com/css?family=Open+Sans:400italic,400,300,600,700" rel="stylesheet" type="text/css">'
    fa_css = '<link rel="stylesheet" href="//maxcdn.bootstrapcdn.com/font-awesome/4.3.0/css/font-awesome.min.css">'

    body = res.body[0]
    body.gsub!(CLOSING_HEAD_REGEX, console_css + font_css + fa_css + '</head>')
    body.gsub!(CLOSING_BODY_REGEX, view.to_html + '</body>')
  end
end

Pakyow::App.before :load do
  Pakyow::Console.boot_plugins
  Pakyow::Console.sass.update_stylesheets
  Pakyow::Console.load_paths.each do |path|
    Pakyow::Console.loader.load_from_path(path)
  end
end

module Sass::Script::Functions
  def mixins
    Sass::Script::List.new(Pakyow::Console.imports, :comma)
  end

  declare :mixins, args: []
end

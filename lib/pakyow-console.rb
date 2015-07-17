require 'pakyow-support'
require 'pakyow-core'
require 'pakyow-presenter'
require 'pakyow-realtime'
require 'pakyow-ui'

require 'pakyow-slim'

require 'sequel'
Sequel::Model.plugin :timestamps, update_on_create: true

require 'image_size'

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

    def self.boot_plugins
      PluginRegistry.boot
    end
  end
end

require_relative 'data_type'
require_relative 'panel'
require_relative 'plugin'
require_relative 'route'
require_relative 'config'
require_relative 'file_store'

require_relative 'registries/data_type_registry'
require_relative 'registries/editor_registry'
require_relative 'registries/panel_registry'
require_relative 'registries/plugin_registry'
require_relative 'registries/route_registry'
require_relative 'registries/datum_processor_registry'
require_relative 'registries/datum_formatter_registry'

require_relative 'editors/string_editor'
require_relative 'editors/text_editor'
require_relative 'editors/enum_editor'
require_relative 'editors/boolean_editor'
require_relative 'editors/monetary_editor'
require_relative 'editors/file_editor'
require_relative 'editors/percentage_editor'
require_relative 'editors/html_editor'

require_relative 'formatters/percentage_formatter'

require_relative 'processors/boolean_processor'
require_relative 'processors/file_processor'
require_relative 'processors/float_processor'
require_relative 'processors/percentage_processor'

Pakyow::Console::PanelRegistry.register :users, mode: :production, nice_name: 'Users', icon_class: 'users' do; end
Pakyow::Console::PanelRegistry.register :release, mode: :development, nice_name: 'Release', icon_class: 'paper-plane' do; end

app_path = File.join(CONSOLE_ROOT, 'app')

Pakyow::Console.add_load_path(app_path)

CLOSING_HEAD_REGEX = /<\/head>/m
CLOSING_BODY_REGEX = /<\/body>/m

Pakyow::App.after :init do
  if Pakyow.app.env == :development
    if info = platform_creds
      @context = Pakyow::AppContext.new
      setup_platform_socket(info)
    end
  end
end

Pakyow::App.after :process do
  if req.path_parts[0] != 'console' && @presenter.presented? && console_authed?
    view = Pakyow::Presenter::ViewContext.new(Pakyow::Presenter::View.new(File.open(File.join(CONSOLE_ROOT, 'views', 'console', '_toolbar.slim')).read, format: :slim), self)
    setup_toolbar(view)

    console_css = '<link href="/console/styles/console-toolbar.css" rel="stylesheet" type="text/css">'
    font_css = '<link href="//fonts.googleapis.com/css?family=Open+Sans:400italic,400,300,600,700" rel="stylesheet" type="text/css">'
    fa_css = '<link rel="stylesheet" href="//maxcdn.bootstrapcdn.com/font-awesome/4.3.0/css/font-awesome.min.css">'

    body = res.body[0]
    body.gsub!(CLOSING_HEAD_REGEX, console_css + font_css + fa_css + '</head>')
    body.gsub!(CLOSING_BODY_REGEX, view.to_html + '</body>')
  end
end

Pakyow::App.before :load do
  Pakyow::Console.boot_plugins

  Pakyow::Console.load_paths.each do |path|
    Pakyow::Console.loader.load_from_path(path)
  end
end

Pakyow::App.before :error do
  if req.path_parts[0] == 'console'
    if !Pakyow::Config.app.errors_in_browser
      presenter.path = 'console/errors/500'
      res.body << presenter.view.composed.to_html
      halt
    end
  end
end

Pakyow::App.after :route do
  if !found? && req.path_parts[0] == 'console'
    presenter.path = 'console/errors/404'
    res.body << presenter.view.composed.to_html
    halt
  end
end

# plugin stubs

# Pakyow::Console::PanelRegistry.register :design, mode: :development, nice_name: 'Design', icon_class: 'eye' do; end
# Pakyow::Console::PanelRegistry.register :plugins, mode: :development, nice_name: 'Plugins', icon_class: 'plug' do; end

# Pakyow::Console::PanelRegistry.register :content, mode: :production, nice_name: 'Pages', icon_class: 'newspaper-o' do; end
# Pakyow::Console::PanelRegistry.register :stats, mode: :production, nice_name: 'Stats', icon_class: 'bar-chart' do; end

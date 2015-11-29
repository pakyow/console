require 'pakyow-support'
require 'pakyow-core'
require 'pakyow-presenter'
require 'pakyow-realtime'
require 'pakyow-ui'

require 'pakyow-assets'
require 'pakyow-slim'

require 'sequel'
Sequel::Model.plugin :timestamps, update_on_create: true

require 'image_size'

CONSOLE_ROOT = File.expand_path('../', __FILE__)
PLATFORM_URL = 'https://pakyow.com'

Pakyow::App.config.presenter.view_stores[:console] = [File.join(CONSOLE_ROOT, 'views')]
Pakyow::App.config.app.resources[:console] = File.join(CONSOLE_ROOT, 'resources')

require_relative 'version'

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

    def self.model(name)
      Object.const_get(Pakyow::Config.console.models[name])
    end

    def self.before(object, action, &block)
      ServiceHookRegistry.register :before, action, object, &block
    end

    def self.after(object, action, &block)
      ServiceHookRegistry.register :after, action, object, &block
    end

    def self.data(type, icon: nil, &block)
      DataTypeRegistry.register type, icon_class: icon, &block
    end

    def self.editor(*types, &block)
      EditorRegistry.register *types, &block
    end

    def self.script(path)
      ScriptRegistry.register path
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
require_relative 'registries/service_hook_registry'
require_relative 'registries/content_type_registry'
require_relative 'registries/script_registry'

require_relative 'editors/string_editor'
require_relative 'editors/text_editor'
require_relative 'editors/enum_editor'
require_relative 'editors/boolean_editor'
require_relative 'editors/monetary_editor'
require_relative 'editors/file_editor'
require_relative 'editors/percentage_editor'
require_relative 'editors/html_editor'
require_relative 'editors/sensitive_editor'
require_relative 'editors/relation_editor'
require_relative 'editors/content_editor'
require_relative 'editors/date_editor'

require_relative 'formatters/percentage_formatter'

require_relative 'processors/boolean_processor'
require_relative 'processors/file_processor'
require_relative 'processors/float_processor'
require_relative 'processors/percentage_processor'
require_relative 'processors/relation_processor'

Pakyow::Console::PanelRegistry.register :release, mode: :development, nice_name: 'Release', icon_class: 'paper-plane' do; end

app_path = File.join(CONSOLE_ROOT, 'app')

Pakyow::Console.add_load_path(app_path)

CLOSING_HEAD_REGEX = /<\/head>/m
CLOSING_BODY_REGEX = /<\/body>/m

Pakyow::App.before :init do
  config.assets.stores[:console] = File.expand_path('../app/assets', __FILE__)
end

Pakyow::App.after :configure do
  begin
    config.app.db
  rescue Pakyow::ConfigError
    Pakyow.logger.info '[console] establishing database connection'

    config.app.db = Sequel.connect(ENV.fetch('DATABASE_URL'))
    config.app.db.extension :pg_json

    Sequel.default_timezone = :utc
    Sequel::Model.plugin :validation_helpers
    Sequel::Model.plugin :timestamps, update_on_create: true
    Sequel.extension :pg_json_ops
  end
end

Pakyow::App.after :init do
  app_migration_dir = File.join(config.app.root, 'migrations')

  if Pakyow.app.env == :development
    if info = platform_creds
      @context = Pakyow::AppContext.new
      setup_platform_socket(info)
    end

    unless File.exists?(app_migration_dir)
      FileUtils.mkdir(app_migration_dir)
      app_migrations = []
    end

    console_migration_dir = File.expand_path('../migrations', __FILE__)
    console_migrations = Dir.glob(File.join(console_migration_dir, '*.rb')).map { |path|
      File.basename(path)
    }

    app_migrations = Dir.glob(File.join(app_migration_dir, '*.rb')).map { |path|
      File.basename(path)
    }

    (console_migrations - app_migrations).each do |migration|
      Pakyow.logger.info "[console] copying migration #{migration}"
      FileUtils.cp(File.join(console_migration_dir, migration), app_migration_dir)
    end
  end

  begin
    Pakyow.logger.info '[console] checking for missing migrations'
    Sequel.extension :migration
    Sequel::Migrator.check_current(config.app.db, app_migration_dir)
  rescue Sequel::Migrator::NotCurrentError
    Pakyow.logger.info '[console] not current; running migrations now'
    Sequel::Migrator.run(config.app.db, app_migration_dir)
  end

  Pakyow.logger.info '[console] migrations are current'
end

Pakyow::App.after :process do
  if req.path_parts[0] != 'console' && @presenter.presented? && console_authed? && res.body
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

  unless Pakyow::Console::DataTypeRegistry.names.include?(:user)
    Pakyow::Console::DataTypeRegistry.register :user, icon_class: 'users' do
      model Pakyow::Config.console.models[:user]

      attribute :name, :string, nice: 'Full Name'
      attribute :username, :string
      attribute :email, :string
      attribute :password, :sensitive
      attribute :password_confirmation, :sensitive
      attribute :active, :boolean

      action :remove, label: 'Delete', notification: 'user deleted' do
        reroute router.group(:datum).path(:remove, data_id: params[:data_id], datum_id: params[:datum_id])
      end
    end
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

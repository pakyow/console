require 'pakyow-support'
require 'pakyow-core'
require 'pakyow-presenter'
require 'pakyow-realtime'
require 'pakyow-ui'

require 'pakyow-assets'
require 'pakyow-slim'

require 'sequel'

Sequel.extension :pg_json_ops
Sequel.default_timezone = :utc

Sequel::Model.plugin :timestamps, update_on_create: true
Sequel::Model.plugin :polymorphic
Sequel::Model.plugin :validation_helpers
Sequel::Model.plugin :uuid
Sequel::Model.plugin :association_dependencies

require 'image_size'

CONSOLE_ROOT = File.expand_path('../', __FILE__)
PLATFORM_URL = 'https://pakyow.com'

Pakyow::App.config.presenter.view_stores[:console] = [File.join(CONSOLE_ROOT, 'views')]

require_relative 'version'

Pakyow::Assets.preprocessor :eot, :svg, :ttf, :woff, :woff2, :otf

module Pakyow
  module Console
    def self.loader
      @loader ||= Pakyow::Loader.new
    end

    def self.load_paths
      @load_paths ||= []
    end

    def self.migration_paths
      @migration_paths ||= []
    end

    def self.imports
      @imports ||= []
    end

    def self.add_load_path(path)
      load_paths << path
    end

    def self.add_migration_path(path)
      migration_paths << path
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

    def self.db
      return @db unless @db.nil?

      Pakyow.logger.info '[console] establishing database connection'

      @db = Sequel.connect(ENV.fetch('DATABASE_URL'))
      @db.extension :pg_json
      @db
    end

    def self.pages
      @pages ||= Pakyow::Console::Models::Page.all
    end

    def self.invalidate_pages
      @pages = nil
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

# make sure this after configure block executes first
# FIXME: need an api for this on Pakyow::App
Pakyow::App.hook(:after, :configure).unshift(lambda  {
  config.assets.stores[:console] = File.expand_path('../app/assets', __FILE__)

  begin
    config.app.db
  rescue Pakyow::ConfigError
    config.app.db = Pakyow::Console.db
  end

  app_migration_dir = File.join(config.app.root, 'migrations')

  if Pakyow::Config.env == :development
    unless File.exists?(app_migration_dir)
      FileUtils.mkdir(app_migration_dir)
      app_migrations = []
    end

    migration_map = {}
    console_migration_dir = File.expand_path('../migrations', __FILE__)
    migration_paths = Pakyow::Console.migration_paths.push(console_migration_dir)
    console_migrations = []

    migration_paths.each do |migration_path|
      console_migrations.concat Dir.glob(File.join(migration_path, '*.rb')).map { |path|
        basename = File.basename(path)
        migration_map[basename] = path
        basename
      }
    end

    app_migrations = Dir.glob(File.join(app_migration_dir, '*.rb')).map { |path|
      File.basename(path)
    }

    (console_migrations - app_migrations).each do |migration|
      Pakyow.logger.info "[console] copying migration #{migration}"
      FileUtils.cp(migration_map[migration], app_migration_dir)
    end
  end

  begin
    Pakyow.logger.info '[console] checking for missing migrations'
    Sequel.extension :migration
    Sequel::Migrator.check_current(config.app.db, app_migration_dir)
  rescue Sequel::DatabaseConnectionError
    Pakyow.logger.warn '[console] could not connect to database'
    next
  rescue Sequel::Migrator::NotCurrentError
    Pakyow.logger.info '[console] not current; running migrations now'
    Sequel::Migrator.run(config.app.db, app_migration_dir)
  end

  Pakyow.logger.info '[console] migrations are current'
})

Pakyow::App.after :init do
  if Pakyow::Config.env == :development
    if info = platform_creds
      @context = Pakyow::AppContext.new
      setup_platform_socket(info)
    end
  end
end

Pakyow::App.hook(:before, :error).unshift(lambda {
  next unless req.path_parts.first == 'console'
  console_handle 500
})

Pakyow::App.after :match do
  # TODO: this guard is needed because the route hooks are called again when calling a handler :/
  if !@console_404 && Pakyow::Console::Models::InvalidPath.invalid_for_path?(req.path)
    @console_404 = true
    handle 404, false
  end

  page = Pakyow::Console.pages.find { |p| p.matches?(req.path) }
  next if page.nil?

  if !@console_404 && !page.published
    @console_404 = true
    handle 404, false
  end

  if page.fully_editable?
    template = presenter.store(:default).template(page.template.to_sym)
    presenter.view = template.build(page).includes(presenter.store(:default).partials('/'))
    presenter.view.title = String.presentable(page.name)
  else
    renderer_view = presenter.store(:console).view('/console/pages/template')
    presenter.view.composed.doc.editables.each do |editable|
      content = page.content_for(editable[:doc].get_attribute(:'data-editable'))
      parts = editable[:doc].editable_parts

      if parts.empty?
        rendered = renderer_view.scope(:content)[0].dup
        Pakyow::Console::ContentRenderer.render(content.content, view: rendered)
        editable[:doc].clear
        editable[:doc].append(rendered.to_html)
      else
        editable[:doc].editable_parts.each_with_index do |part, i|
          rendered = renderer_view.scope(:content)[0].dup

          Pakyow::Console::ContentRenderer.render([content.content[i]], view: rendered, constraints: page.constraints)
          part[:doc].replace(rendered.to_html)
        end
      end
    end
  end
end

Pakyow::App.after :process do
  if req.path_parts[0] != 'console' && @presenter && @presenter.presented? && console_authed? && res.body && res.body.is_a?(Array)
    view = Pakyow::Presenter::ViewContext.new(Pakyow::Presenter::View.new(File.open(File.join(CONSOLE_ROOT, 'views', 'console', '_toolbar.slim')).read, format: :slim), self)
    setup_toolbar(view)

    console_css = '<link href="/console/styles/console-toolbar.css" rel="stylesheet" type="text/css">'

    if config.assets.compile_on_startup
      console_css = Pakyow::Assets.mixin_fingerprints(console_css)
    end

    font_css = '<link href="//fonts.googleapis.com/css?family=Open+Sans:400italic,400,300,600,700" rel="stylesheet" type="text/css">'
    fa_css = '<link rel="stylesheet" href="//maxcdn.bootstrapcdn.com/font-awesome/4.3.0/css/font-awesome.min.css">'

    body = res.body[0]
    body.gsub!(CLOSING_HEAD_REGEX, console_css + font_css + fa_css + '</head>')
    body.gsub!(CLOSING_BODY_REGEX, view.to_html + '</body>')
  end
end

Pakyow::App.before :load do
  Pakyow::Console.boot_plugins
end

Pakyow::App.after :load do
  Pakyow::Console.load_paths.each do |path|
    Pakyow::Console.loader.load_from_path(path)
  end

  # make sure the console routes are last (since they have the catch-all)
  Pakyow::App.routes[:console] = Pakyow::App.routes.delete(:console)

  unless Pakyow::Console::DataTypeRegistry.names.include?(:user)
    Pakyow::Console::DataTypeRegistry.register :user, icon_class: 'users' do
      model Pakyow::Config.console.models[:user]
      pluralize

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

  unless Pakyow::Console::DataTypeRegistry.names.include?(:page)
    Pakyow::Console::DataTypeRegistry.register :page, icon_class: 'columns' do
      model Pakyow::Config.console.models[:page]
      pluralize

      attribute :name, :string, nice: 'Page Name'

      attribute :slug, :string, display: -> (datum) {
        !datum.nil? && !datum.id.nil?
      }, nice: 'Page Path'

      # TODO: (later) add more user-friendly template descriptions (embedded in the top-matter?)
      attribute :page, :relation, class: Pakyow::Config.console.models[:page], nice: 'Parent Page', relationship: :parent

      # TODO: (later) add configuration to containers so that content can be an image or whatever (look at GIRT)
      # TODO: (later) we definitely need the concept of content templates (perhaps in _content) or something
      attribute :template, :enum, values: Pakyow.app.presenter.store.templates.keys.map { |k| [k,k] }.unshift(['', '']), display: -> (datum) {
        datum.nil? || datum.fully_editable?
      }, nice: 'Layout'

      dynamic do |page|
        next unless page.is_a?(Pakyow::Console::Models::Page)

        if page.fully_editable?
          Pakyow.app.presenter.store(:default).template(page.template.to_sym).doc.containers.each do |container|
            attribute :"content-#{container[0]}", :content, nice: container[0].capitalize, value: -> (page) {
              content = page.content_for(container[0])
              content.content unless content.nil?
            }, setter: -> (page, params) {
              Pakyow.app.presenter.store(:default).template(page.template.to_sym).doc.containers.each do |container|
                container_name = container[0]
                content = page.content_for(container_name)
                content.update(content: params[:"content-#{container_name}"])
              end
            }
          end
        else
          page.editables.each do |editable|
            attribute :"content-#{editable[:id]}", :content, nice: editable[:id].to_s.capitalize, value: -> (page) {
              page.content_for(editable[:id]).content
            }, setter: -> (page, params) {
              page.editables.each do |editable|
                content = page.content_for(editable[:id])
                content.update(content: params[:"content-#{editable[:id]}"])
              end
            }, restricted: true, constraints: page.constraints
          end
        end
      end

      # TODO: (later) we need a metadata editor with the ability for the user to add k / v OR for the editor to define keys

      action :delete, label: 'Delete' do |page|
        page.destroy
        notify("#{page.name} page deleted", :success)
        redirect router.group(:data).path(:show, data_id: params[:data_id])
      end

      action :publish,
             label: 'Publish',
             notification: 'page published',
             display: ->(page) { !page.published? } do |page|
        page.published = true
        page.save

        Pakyow::Console.invalidate_pages
      end

      action :unpublish,
             label: 'Unpublish',
             notification: 'page unpublished',
             display: ->(page) { page.published? } do |page|
        page.published = false
        page.save

        Pakyow::Console.invalidate_pages
      end
    end
  end

  presenter.store(:default).views do |view, path|
    composer = presenter.store(:default).composer(path)
    next unless composer.page.path.include?(path)

    editables = view.doc.editables
    next if editables.empty?

    path = String.slugify(path)
    next if Pakyow::Console::Models::InvalidPath.invalid_for_path?(path)
    page = Pakyow::Console::Models::Page.where(slug: path).first

    if page.nil?
      page = Pakyow::Console::Models::Page.new
      page.slug = path
      page.name = path.split('/').last || 'home'
      page.find_and_set_parent
      page.template = :__editable
      page.published = true
      page.save
    end

    composer = presenter.store(:default).composer(path)

    config.app.db.transaction do
      Pakyow::Console::Models::Page.editables_for_view(view).each do |editable|
        next if page.content_for(editable[:id])
        parts = editable[:doc].editable_parts

        if parts.empty?
          content = {
            id: SecureRandom.uuid,
            scope: :content,
            type: :default,
            content: editable[:doc].html
          }

          page.add_content(content: [content], metadata: { id: editable[:id] })
        else
          content = []
          parts.each do |part|
            part_type = part[:doc].get_attribute(:'data-editable-part').to_sym
            part_alignment = part[:doc].get_attribute(:'data-align')
            part_hash = {
              id: SecureRandom.uuid,
              scope: :content,
              type: part_type,
              align: part_alignment,
            }

            if part_type == :default
              part_hash[:content] = part[:doc].html
            elsif part_type == :image
              part_hash[:images] = []
            end

            content << part_hash
          end

          page.add_content(content: content, metadata: { id: editable[:id] })
        end
      end
    end
  end

  # TODO: (later) we need a navigation datatype; this would let you build a navigation containing particular
  #   pages, plugin endpoints, etc; essentially anything that registers a route with console.
  #   the items could be ordered with each navigation.
  #   nested pages would be taken into account somehow.
  #   we'd need to figure out the rendering; perhaps we'll have to define navigation types (extendable)...
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

Pakyow::Presenter::StringDocParser::SIGNIFICANT << :editable?
Pakyow::Presenter::StringDocParser::SIGNIFICANT << :editable_part?

module Pakyow
  module Presenter
    class StringDocParser
      private

      def editable?(node)
        return false unless node.is_a?(Oga::XML::Element)
        return false unless node.attribute('data-editable')
        return true
      end

      def editable_part?(node)
        return false unless node.is_a?(Oga::XML::Element)
        return false unless node.attribute('data-editable-part')
        return true
      end
    end

    class StringDoc
      def editables
        find_editables(@node ? [@node] : @structure)
      end

      def editable_parts
        find_editable_parts(@node ? [@node] : @structure)
      end

      private

      def find_editables(structure, primary_structure = @structure, editables = [])
        ret_editables = structure.inject(editables) { |s, e|
          if e[1].has_key?(:'data-editable')
            s << {
              doc: StringDoc.from_structure(primary_structure, node: e),
              editable: e[1][:'data-editable'].to_sym,
            }
          end
          find_editables(e[2], e[2], s)
          s
        } || []

        ret_editables
      end

      def find_editable_parts(structure, primary_structure = @structure, editable_parts = [])
        ret_editable_parts = structure.inject(editable_parts) { |s, e|
          if e[1].has_key?(:'data-editable-part')
            s << {
              doc: StringDoc.from_structure(primary_structure, node: e),
              editable_part: e[1][:'data-editable-part'].to_sym,
            }
          end
          find_editable_parts(e[2], e[2], s)
          s
        } || []

        ret_editable_parts
      end
    end
  end
end

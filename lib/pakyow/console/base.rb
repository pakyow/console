module Pakyow
  module Console
    ROOT = File.expand_path('../../', __FILE__)
    CLOSING_HEAD_REGEX = /<\/head>/m
    CLOSING_BODY_REGEX = /<\/body>/m
    RFC882 = "%a, %d %b %Y %H:%M:%S %Z"

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

    def self.slug_handlers
      @slug_handler ||= []
    end

    def self.add_load_path(path)
      load_paths << path
    end

    def self.add_migration_path(path)
      migration_paths << path
    end

    def self.boot_plugins
      return if @booted

      PluginRegistry.boot
      @booted = true
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

    def self.plugin(type, &block)
      PluginRegistry.register type, &block
    end

    def self.robots
      return @robots unless @robots.nil?

      @robots = RobotsTxt.new

      # create the console defaults
      @robots.agent '*' do |agent|
        agent.allow '/'
        agent.disallow '/console'
        agent.allow '/console/files'
      end

      @robots
    end

    def self.sitemap
      @sitemap ||= SitemapXML.new
    end

    def self.db
      return @db unless @db.nil?

      Pakyow.logger.info '[console] establishing database connection'

      @db = Sequel.connect(ENV.fetch('DATABASE_URL'))
      @db.extension :pg_json
    end

    def self.endpoints
      return @endpoints if @endpoints

      @endpoints = []
      @endpoints.concat Pakyow::Console::Models::Page.all
      @endpoints.concat Pakyow::Console::Models::Collection.all
      @endpoints
    end

    def self.invalidate_endpoints
      @endpoints = nil
    end

    def self.load
      return if @loaded

      # make sure the console routes are last (since they have the catch-all)
      Pakyow::App.routes[:console] = Pakyow::App.routes.delete(:console)

      Pakyow.app.presenter.store(:default).views do |view, path|
        composer = Pakyow.app.presenter.store(:default).composer(path)

        # handles cases where we use a parent page because the child doesn't define their own
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

        page.find_and_create_editables

        # build navigations + items
        navigation_and_group = composer.page.info(:navigation)
        next if navigation_and_group.nil?

        navigation_name, group_name = navigation_and_group.to_s.split('/')

        navigation = Pakyow::Console::Models::Navigation.find_or_create(name: navigation_name)
        Pakyow::Console::Models::NavigationItem.find_or_create(navigation: navigation, endpoint_id: page.id, endpoint_type: page.class.name, group: group_name)
      end

      @loaded = true

      # TODO: (later) we need a navigation datatype; this would let you build a navigation containing particular
      #   pages, plugin endpoints, etc; essentially anything that registers a route with console.
      #   the items could be ordered with each navigation.
      #   nested pages would be taken into account somehow.
      #   we'd need to figure out the rendering; perhaps we'll have to define navigation types (extendable)...
    end

    def self.setup_db
      return if @db

      begin
        Pakyow::Config.app.db
      rescue Pakyow::ConfigError
        Pakyow::Config.app.db = Pakyow::Console.db
      end

      if Pakyow::Config.env == :development
        app_migration_dir = File.join(Pakyow::Config.app.root, 'migrations')

        unless File.exists?(app_migration_dir)
          FileUtils.mkdir(app_migration_dir)
          app_migrations = []
        end

        migration_map = {}
        console_migration_dir = File.expand_path('../../migrations', __FILE__)
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

        begin
          Pakyow.logger.info '[console] checking for missing migrations'
          Sequel.extension :migration
          Sequel::Migrator.check_current(Pakyow::Config.app.db, app_migration_dir)
        rescue Sequel::DatabaseConnectionError
          Pakyow.logger.warn '[console] could not connect to database'
          return
        rescue Sequel::Migrator::NotCurrentError
          Pakyow.logger.info '[console] not current; running migrations now'
          Sequel::Migrator.run(Pakyow::Config.app.db, app_migration_dir)
        end

        Pakyow.logger.info '[console] migrations are current'
      end

      @db = true
    end

    def self.slug_handler(&block)
      slug_handlers << block
    end

    def self.handle_slug(ctx)
      ctx.handle 404 if Pakyow::Console::Models::InvalidPath.invalid_for_path?(ctx.req.path)

      slug_handlers.each do |handler|
        ctx.instance_exec(&handler)
      end

      ctx.handle 404
    end

    def self.mount_plugins(ctx, loading: false)
      deleteable = []
      Pakyow::Router.instance.sets.each_pair do |key, value|
        next unless key.to_s.start_with?('pw-')
        deleteable << key
      end

      deleteable.each do |key|
        Pakyow::Router.instance.sets.delete(key)
      end

      Pakyow::Console::Models::MountedPlugin.where(active: true).order(Sequel.desc(:slug)).all.each do |plugin|
        Pakyow::Router.instance.set :"pw-blog=#{plugin.id}" do
          include Object.const_get("Pakyow::Console::Plugins::#{Inflecto.camelize(plugin.name)}::Routes")
          include Pakyow::Console::SharedRoutes

          fn :set_plugin do
            @mounted_plugin = plugin
          end

          fn :mixin_view do
            begin
              mixin_view(File.join("pw-#{current_plugin.name}", req.path), current_plugin.name.to_sym)
            rescue Pakyow::Presenter::MissingView
              mixin_view(File.join("pw-#{current_plugin.name}", "show"), current_plugin.name.to_sym)
            end
          end

          send plugin.name.to_sym, :"pw-blog-#{plugin.id}", plugin.slug, before: [:set_plugin, :mixin_view, :prepare_project] do
            plugin_obj = Pakyow::Console::PluginRegistry.find(plugin.name)

            plugin_obj.routes.each do |route_name|
              action route_name
            end
          end
        end
      end

      Pakyow::Router.instance.sets[:'console-catchall'] = Pakyow::Router.instance.sets.delete(:'console-catchall')
    end
  end
end

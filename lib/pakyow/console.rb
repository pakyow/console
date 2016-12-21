require 'pakyow-support'
require 'pakyow-core'
require 'pakyow-presenter'
require 'pakyow-realtime'
require 'pakyow-ui'

require 'pakyow-assets'
require 'pakyow-slim'

require 'image_size'
require 'sequel'
require 'oauth'

require 'pakyow/console/base'
require 'pakyow/console/version'

require 'pakyow/console/data_type'
require 'pakyow/console/panel'
require 'pakyow/console/plugin'
require 'pakyow/console/route'
require 'pakyow/console/config'
require 'pakyow/console/file_store'
require 'pakyow/console/hooks'
require 'pakyow/console/editables'
require 'pakyow/console/navigations'

require 'pakyow/console/registries/data_type_registry'
require 'pakyow/console/registries/editor_registry'
require 'pakyow/console/registries/panel_registry'
require 'pakyow/console/registries/plugin_registry'
require 'pakyow/console/registries/route_registry'
require 'pakyow/console/registries/datum_processor_registry'
require 'pakyow/console/registries/datum_formatter_registry'
require 'pakyow/console/registries/service_hook_registry'
require 'pakyow/console/registries/content_type_registry'
require 'pakyow/console/registries/script_registry'

require 'pakyow/console/editors/string_editor'
require 'pakyow/console/editors/text_editor'
require 'pakyow/console/editors/enum_editor'
require 'pakyow/console/editors/boolean_editor'
require 'pakyow/console/editors/monetary_editor'
require 'pakyow/console/editors/file_editor'
require 'pakyow/console/editors/percentage_editor'
require 'pakyow/console/editors/html_editor'
require 'pakyow/console/editors/sensitive_editor'
require 'pakyow/console/editors/relation_editor'
require 'pakyow/console/editors/content_editor'
require 'pakyow/console/editors/date_editor'
require 'pakyow/console/editors/datetime_editor'

require 'pakyow/console/formatters/percentage_formatter'
require 'pakyow/console/formatters/datetime_formatter'

require 'pakyow/console/processors/boolean_processor'
require 'pakyow/console/processors/file_processor'
require 'pakyow/console/processors/float_processor'
require 'pakyow/console/processors/percentage_processor'
require 'pakyow/console/processors/relation_processor'
require 'pakyow/console/processors/content_processor'

require 'pakyow/console/robots'
require 'pakyow/console/sitemap'

# sequel config
#
Sequel.extension :pg_json
Sequel.extension :pg_json_ops
Sequel.default_timezone = :utc

Sequel::Model.plugin :timestamps, update_on_create: true
Sequel::Model.plugin :polymorphic
Sequel::Model.plugin :validation_helpers
Sequel::Model.plugin :uuid
Sequel::Model.plugin :association_dependencies
Sequel::Model.plugin :dirty
#
# /sequel

# misc pakyow config
#
# register console views
Pakyow::App.config.presenter.view_stores[:console] = [File.join(Pakyow::Console::ROOT, 'views')]
# register console assets
Pakyow::App.config.assets.stores[:console] = File.join(Pakyow::Console::ROOT, 'app', 'assets')
# register asset types that console has
Pakyow::Assets.preprocessor :eot, :svg, :ttf, :woff, :woff2, :otf
# register all app files to be loaded
Pakyow::Console.add_load_path(File.join(Pakyow::Console::ROOT, 'app'))
#
# /misc

# panes
#
# Pakyow::Console::PanelRegistry.register :plugins, mode: :production, nice_name: 'Plugins', icon_class: 'plug' do; end
# Pakyow::Console::PanelRegistry.register :routes, mode: :development, nice_name: 'Routes', icon_class: 'map' do; end
#
# /panes

# plugin stubs
#
# Pakyow::Console::PanelRegistry.register :design, mode: :development, nice_name: 'Design', icon_class: 'eye' do; end
# Pakyow::Console::PanelRegistry.register :content, mode: :production, nice_name: 'Pages', icon_class: 'newspaper-o' do; end
# Pakyow::Console::PanelRegistry.register :stats, mode: :production, nice_name: 'Stats', icon_class: 'bar-chart' do; end
# TODO: move release to a separate plugin
# Pakyow::Console::PanelRegistry.register :release, mode: :development, nice_name: 'Release', icon_class: 'paper-plane' do; end
#
# /plugins

unless Pakyow::Console::DataTypeRegistry.names.include?(:user)
  Pakyow::Console::DataTypeRegistry.register :user, icon_class: 'users' do
    model Pakyow::Config.console.models[:user]
    pluralize
    settings

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
  Pakyow::Console::DataTypeRegistry.register :page, icon_class: 'file-text-o' do
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
    attribute :template, :enum, values: -> { Pakyow.app.presenter.store.templates.keys.map { |k| [k,k] }.unshift(['', '']) }, display: -> (datum) {
      datum.nil? || datum.fully_editable?
    }, nice: 'Layout'

    dynamic do |page|
      next unless page.is_a?(Pakyow::Console::Models::Page) && page.id

      if page.fully_editable?
        Pakyow.app.presenter.store(:default).template(page.template.to_sym).doc.containers.each do |container|
          attribute :"content-#{container[0]}", :content, nice: container[0].capitalize, value: -> (page) {
            content = page.content_for(container[0])
            content.content unless content.nil?
          }, setter: -> (page, params, processor) {
            Pakyow.app.presenter.store(:default).template(page.template.to_sym).doc.containers.each do |container|
              container_name = container[0]
              content = page.content_for(container_name)
              value = params[:"content-#{container_name}"]
              value = processor.call(value) if processor
              content.update(content: value)
            end
          }
        end
      end

      page.editables.each do |editable|
        attribute :"content-#{editable[:id]}", :content, nice: editable[:id].to_s.capitalize, value: -> (page) {
          page.content_for(editable[:id]).content
        }, setter: -> (page, params, processor) {
          page.editables.each do |editable|
            content = page.content_for(editable[:id])
            value = params[:"content-#{editable[:id]}"]
            value = processor.call(value) if processor
            content.update(content: value)
          end
        }, restricted: editable[:doc].editable_parts.count > 0 && !editable[:doc].has_attribute?(:'data-editable-unrestrict'), constraints: editable[:constraints]
      end
    end

    # TODO: (later) we need a metadata editor with the ability for the user to add k / v OR for the editor to define keys

    action :delete, label: 'Delete' do |page|
      page.destroy
      notify("#{page.name} page deleted", :success)

      Pakyow::Console.sitemap.delete_location(
        File.join(Pakyow::Config.app.uri, page.slug)
      )

      redirect router.group(:data).path(:show, data_id: 'page')
    end

    action :publish,
           label: 'Publish',
           notification: 'page published',
           display: ->(page) { !page.published? } do |page|
      page.published = true
      page.save

      Pakyow::Console.sitemap.url(
        location: File.join(Pakyow::Config.app.uri, page.slug),
        modified: page.updated_at.httpdate
      )

      Pakyow::Console.invalidate_pages
    end

    action :unpublish,
           label: 'Unpublish',
           notification: 'page unpublished',
           display: ->(page) { page.published? } do |page|
      page.published = false
      page.save

      Pakyow::Console.sitemap.delete_location(
        File.join(Pakyow::Config.app.uri, page.slug)
      )

      Pakyow::Console.invalidate_pages
    end
  end

  Pakyow::Console.after :page, :create do |page|
    if page.published?
      Pakyow::Console.sitemap.url(
        location: File.join(Pakyow::Config.app.uri, page.slug),
        modified: page.updated_at.httpdate
      )
    end
  end

  Pakyow::Console.after :page, :update do |page|
    if page.published?
      Pakyow::Console.sitemap.delete_location(
        File.join(Pakyow::Config.app.uri, page.initial_value(:slug))
      )

      Pakyow::Console.sitemap.url(
        location: File.join(Pakyow::Config.app.uri, page.slug),
        modified: page.updated_at.httpdate
      )
    end
  end
end

unless Pakyow::Console::DataTypeRegistry.names.include?(:mount)
  # Pakyow::Console::DataTypeRegistry.register :mount, icon_class: 'cubes' do
  #   model 'Pakyow::Console::Models::MountedPlugin'
  #   pluralize

  #   attribute :slug, :string
  #   attribute :active, :boolean

  #   # FIXME: rename `name` to `type` in model
  #   attribute :name, :enum, nice: 'Plugin', values: Pakyow::Console::PluginRegistry.all.map { |p| [p.id, p.name] }.unshift(['', ''])

  #   action :remove, label: 'Delete', notification: 'mount point deleted' do
  #     # TODO: hook this up
  #   end
  # end
end

Pakyow::Console::PanelRegistry.register :discover, nice_name: "Discover", icon_class: "compass"
Pakyow::Console::PanelRegistry.register :settings, nice_name: "Settings", icon_class: "cog"

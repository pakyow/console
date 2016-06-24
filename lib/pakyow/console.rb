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

# sequel config
#
Sequel.extension :pg_json_ops
Sequel.default_timezone = :utc

Sequel::Model.plugin :timestamps, update_on_create: true
Sequel::Model.plugin :polymorphic
Sequel::Model.plugin :validation_helpers
Sequel::Model.plugin :uuid
Sequel::Model.plugin :association_dependencies
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

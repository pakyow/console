# register console views
Pakyow::App.config.presenter.view_stores[:console] = [File.join(Pakyow::Console::ROOT, 'views')]

# register console assets
Pakyow::App.config.assets.stores[:console] = File.join(Pakyow::Console::ROOT, 'app', 'assets')
Pakyow::Assets.preprocessor :eot, :svg, :ttf, :woff, :woff2, :otf

# misc sequel config
Sequel.extension :pg_json_ops
Sequel.default_timezone = :utc

# load sequel plugins
Sequel::Model.plugin :uuid
Sequel::Model.plugin :timestamps, update_on_create: true
Sequel::Model.plugin :polymorphic
Sequel::Model.plugin :validation_helpers
Sequel::Model.plugin :association_dependencies

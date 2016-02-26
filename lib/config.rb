require_relative 'file_store_adapters/database_adapter'

Pakyow::Config.register(:console) { |config|

  config.opt :use_pakyow_platform, true

  config.opt :models, {
    user: 'Pakyow::Console::User',
    page: 'Pakyow::Console::Page'
  }

  config.opt :file_store_adapter, Pakyow::Console::DBFileAdapter
  config.opt :file_storage_path

}.env(:development) { |opts|

  opts.file_storage_path = lambda {
    File.join(Pakyow::Config.app.root, 'files')
  }

}.env(:staging) { |opts|

  opts.file_storage_path = lambda {
    File.join(Pakyow::Config.app.root, 'system', 'files')
  }

}.env(:production) { |opts|

  opts.file_storage_path = lambda {
    File.join(Pakyow::Config.app.root, 'system', 'files')
  }

}

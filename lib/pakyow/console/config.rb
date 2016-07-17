require_relative 'file_store_adapters/platform_adapter'

Pakyow::Config.register(:console) { |config|

  config.opt :use_pakyow_platform, true

  config.opt :platform_url, 'https://www.pakyow.com'
  config.opt :platform_key, -> { ENV['PLATFORM_OAUTH_KEY'] }
  config.opt :platform_secret, -> { ENV['PLATFORM_OAUTH_SECRET'] }

  config.opt :models, {
    user: 'Pakyow::Console::Models::User',
    page: 'Pakyow::Console::Models::Page'
  }

  config.opt :file_store_adapter, Pakyow::Console::PlatformFileAdapter
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

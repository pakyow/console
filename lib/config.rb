Pakyow::Config.register(:console) { |config|

  config.opt :file_storage_path
  config.opt :use_pakyow_platform, true

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

Pakyow::Console::PluginRegistry.register :core do |plugin|
  plugin.version = '0.1.0'

  boot do
  end

  config do
  end

  function :redirect, destination: nil do |options|
    redirect options[:destination]
  end
end

module Pakyow::Console::PluginRegistry
  def self.register(name, &block)
    plugins[name] = Pakyow::Console::Plugin.new(name, &block)

    path = File.dirname(String.parse_path_from_caller(caller[1]))
    Pakyow::Console.add_migration_path File.join(path, 'migrations')
    Pakyow::App.config.presenter.view_stores[:blog] = File.join(path, 'views')
  end

  def self.boot
    all.each(&:boot)
  end

  def self.all
    plugins.values
  end

  def self.find(name)
    plugins[name.to_sym]
  end

  # def self.functions
  #   @plugins.flat_map { |name, plugin|
  #     plugin.functions.map { |function_name, function|
  #       "#{name}.#{function_name}"
  #     }
  #   }.sort
  # end

  private

  def self.plugins
    @plugins ||= {}
  end
end

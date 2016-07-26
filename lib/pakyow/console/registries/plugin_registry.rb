module Pakyow::Console::PluginRegistry
  def self.register(name, &block)
    path = File.dirname(String.parse_path_from_caller(caller[1]))
    plugins[name] = Pakyow::Console::Plugin.new(name, path, &block)

    migrations_path = File.join(path, 'migrations')
    Pakyow::Console.add_migration_path(migrations_path) if File.exists?(migrations_path)
    
    views_path = File.join(path, 'views')
    Pakyow::App.config.presenter.view_stores[name] = views_path if File.exists?(views_path)
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

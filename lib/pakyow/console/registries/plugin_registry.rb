module Pakyow::Console::PluginRegistry
  def self.register(name, &block)
    plugins[name] = Pakyow::Console::Plugin.new(name, &block)
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

  def self.functions
    @plugins.flat_map { |name, plugin|
      plugin.functions.map { |function_name, function|
        "#{name}.#{function_name}"
      }
    }.sort
  end

  private

  def self.plugins
    @plugins ||= {}
  end
end

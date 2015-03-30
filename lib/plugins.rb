module Pakyow::Console::Plugins
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

module Pakyow::Console
  class Plugin
    attr_reader :id, :name, :functions
    attr_accessor :version, :mountable

    def [](var)
      instance_variable_get(:"@#{var}")
    end

    def initialize(name, &block)
      @id = name
      @name = name
      @functions = {}
      instance_exec(self, &block)
    end

    def boot(&block)
      if block_given?
        @boot_block = block
      else
        @boot_block.call
      end
    end

    def function(name, options = {}, &block)
      @functions[name] = {
        block: block,
        options: options
      }
    end

    def invoke(fn_name, context, options)
      context.instance_exec(options, &@functions[fn_name.to_sym][:block])
    end

    private

    def config(&block)
      Pakyow::Config.register(name) do |config|
        config.instance_exec(&block)
      end
    end
  end
end

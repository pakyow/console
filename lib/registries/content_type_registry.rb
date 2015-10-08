module Pakyow::Console::ContentTypeRegistry
  def self.names
    types.keys
  end

  def self.types
    types.values
  end

  def self.register(name, klass)
    types[name] = klass
  end

  def self.type(name)
    @types[name.to_sym]
  end

  def self.reset
    @types = nil
  end

  private

  def self.types
    @types ||= {}
  end
end

module Pakyow::Console::DataTypeRegistry
  def self.types
    datatypes.values
  end

  def self.register(name, &block)
    datatypes[name] = Pakyow::Console::DataType.new(name, &block)
  end

  def self.type(name)
    @datatypes[name.to_sym]
  end

  private

  def self.datatypes
    @datatypes ||= {}
  end
end

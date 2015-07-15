module Pakyow::Console::DataTypeRegistry
  UNLISTABLE_TYPES = [:text, :file, :media, :html]

  def self.types
    datatypes.values
  end

  def self.register(name, icon_class: nil, &block)
    datatypes[name] = Pakyow::Console::DataType.new(name, icon_class, &block)
  end

  def self.type(name)
    @datatypes[name.to_sym]
  end

  def self.reset
    @datatypes = nil
  end

  private

  def self.datatypes
    @datatypes ||= {}
  end
end

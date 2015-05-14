class Pakyow::Console::DataType
  attr_reader :id, :name
  attr_accessor :model

  def initialize(name, &block)
    @id = name
    @name = name
    @relations = {}
    @attributes = {}
    instance_exec(self, &block)
  end

  def related_to(name, as: nil)
    @relations[name] = as || name
  end

  def reference(&block)
    @reference = block
  end

  def attribute(name, type)
    @attributes[name] = type
  end

  def attributes
    @attributes.map { |attribute|
      {
        name: attribute[0],
        type: attribute[1]
      }
    }
  end

  def [](var)
    instance_variable_get(:"@#{var}")
  end

  def model_object
    Object.const_get(model)
  end
end

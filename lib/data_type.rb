class Pakyow::Console::DataType
  attr_reader :id, :name
  attr_accessor :model

  def initialize(name, &block)
    @id = name
    @name = name
    @relations = {}
    @attributes = {}
    @nice_names = {}
    @extras = {}
    instance_exec(self, &block)
  end

  def related_to(name, as: nil)
    @relations[name] = as || name
  end

  def reference(&block)
    @reference = block
  end

  def attribute(name, type, nice: nil, **extras)
    @attributes[name] = type
    @nice_names[name] = nice unless nice.nil?
    @extras[name] = extras
  end

  def attributes
    @attributes.map { |attribute|
      {
        name: attribute[0],
        type: attribute[1],
        nice: @nice_names.fetch(attribute[0], Inflecto.humanize(attribute[0])),
        extras: @extras[attribute[0]],
      }
    }
  end

  def [](var)
    instance_variable_get(:"@#{var}")
  end

  def model_object
    Object.const_get(model)
  end

  def nice_name
    Inflecto.humanize(Inflecto.underscore(name.to_s))
  end
end

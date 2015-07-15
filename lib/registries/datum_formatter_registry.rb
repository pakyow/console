module Pakyow::Console::DatumFormatterRegistry
  def self.register(*types, &block)
    types.each do |type|
      datum_formatters[type] = block
    end
  end

  def self.format(datum, as: nil)
    as.attributes.inject({}) do |acc, attribute|
      name = attribute[:name]
      type = attribute[:type]

      begin
        acc[name] = datum_formatters.fetch(type).call(datum[name])
      rescue KeyError
        acc[name] = datum[name]
      end

      acc
    end
  end

  def self.reset
    @datum_formatters = nil
  end

  private

  def self.datum_formatters
    @datum_formatters ||= {}
  end
end

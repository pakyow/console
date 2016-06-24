module Pakyow::Console::DatumFormatterRegistry
  def self.register(*types, &block)
    types.each do |type|
      datum_formatters[type] = block
    end
  end

  def self.format(datum, as: nil)
    formatted = datum.values.dup

    as.attributes.each do |attribute|
      name = attribute[:name]
      type = attribute[:type]

      begin
        formatted[name] = datum_formatters.fetch(type).call(datum.send(name))
      rescue KeyError
      end
    end

    formatted
  end

  def self.reset
    @datum_formatters = nil
  end

  private

  def self.datum_formatters
    @datum_formatters ||= {}
  end
end

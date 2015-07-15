module Pakyow::Console::DatumProcessorRegistry
  def self.register(*types, &block)
    types.each do |type|
      datum_processors[type] = block
    end
  end

  def self.process(params, datum = {}, as: nil)
    as.attributes.inject({}) do |acc, attribute|
      name = attribute[:name]
      type = attribute[:type]

      begin
        acc[name] = datum_processors.fetch(type).call(params[name], datum[name])
      rescue KeyError
        acc[name] = params[name]
      end

      acc
    end
  end

  def self.reset
    @datum_processors = nil
  end

  private

  def self.datum_processors
    @datum_processors ||= {}
  end
end

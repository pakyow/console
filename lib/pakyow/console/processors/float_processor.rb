Pakyow::Console::DatumProcessorRegistry.register :monetary, :float do |value|
  value.gsub(/[^0-9\.]/, '').to_f
end

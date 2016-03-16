Pakyow::Console::DatumProcessorRegistry.register :percentage do |value|
  value.gsub(/[^0-9\.]/, '').to_f / 100
end

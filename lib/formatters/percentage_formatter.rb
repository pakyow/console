Pakyow::Console::DatumFormatterRegistry.register :percentage do |value|
  if value
    value * 100
  end
end

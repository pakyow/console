Pakyow::Console::DatumFormatterRegistry.register :relation do |value|
  if value
    value.relation_name
  end
end

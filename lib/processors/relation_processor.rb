Pakyow::Console::DatumProcessorRegistry.register :relation do |value|
  if value.empty?
    nil
  else
    klass, id = value.split(':')
    Object.const_get(klass)[id.to_i]
  end
end

Pakyow::Console::DatumProcessorRegistry.register :relation do |value|
  if value.empty?
    nil
  else
    klass, id = value.split('__')
    Object.const_get(klass)[id]
  end
end

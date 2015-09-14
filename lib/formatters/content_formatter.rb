Pakyow::Console::DatumFormatterRegistry.register :content do |value|
  value ? value['content'] : ''
end

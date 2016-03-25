Pakyow::Console::DatumFormatterRegistry.register :datetime do |value|
  value.strftime('%d %b %Y @ %k:%M') if value
end

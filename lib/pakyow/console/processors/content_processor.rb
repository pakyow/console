Pakyow::Console::DatumProcessorRegistry.register :content do |value|
  json = JSON.parse(value)

  json.each do |content|
    next unless content['type'] == 'default'

    content['content'].gsub!('<div>', '<p>')
    content['content'].gsub!('</div>', '</p>')
  end

  json.to_json
end

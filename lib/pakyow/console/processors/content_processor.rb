Pakyow::Console::DatumProcessorRegistry.register :content do |value|
  json = JSON.parse(value)
  processor = Pakyow.app.presenter.processor_store[:md]

  json.each do |content|
    next unless content['type'] == 'default'
    
    # always store content as html
    content['content'] = processor.call(content['content'])
  end

  json.to_json
end

Pakyow::Console::DatumProcessorRegistry.register :file do |file, current|
  if file.is_a?(Hash)
    filename, tempfile = file.values_at(:filename, :tempfile)
    Pakyow::Console::FileStore.instance.store(filename, tempfile)[:id]
  elsif file == 'delete'
    nil
  else
    current
  end
end

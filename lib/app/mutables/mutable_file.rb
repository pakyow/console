Pakyow::App.mutable :file do
  query :all_of_type do |type|
    type = type.to_s
    Pakyow::Console::FileStore.instance.files.select { |f|
      f[:type] == type
    }.sort { |a, b| a[:filename].downcase <=> b[:filename].downcase }
  end

  action :create do |name, file|
    Pakyow::Console::FileStore.instance.store!(name, file)
  end
end

Pakyow::App.bindings :'console-setting-item' do
  scope :'console-setting-item' do
    binding :icon do
      {
        class: "fa fa-#{bindable[:icon_class]}"
      }
    end

    binding :href do
      {
        href: "/console/#{bindable[:namespace]}"
      }
    end
  end
end

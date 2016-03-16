Pakyow::App.bindings :'console-panel-item' do
  scope :'console-panel-item' do
    binding :icon do
      {
        class: "fa fa-#{bindable[:icon_class]}"
      }
    end

    binding :link do
      {
        href: "/console/#{bindable[:namespace]}",
        content: bindable[:nice_name]
      }
    end
  end
end

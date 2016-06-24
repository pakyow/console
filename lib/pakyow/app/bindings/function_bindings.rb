Pakyow::App.bindings :'console-function' do
  scope :'console-function' do
    restful :'console-function'

    binding :edit_link do
      {
        content: "#{bindable[:plugin]}.#{bindable[:function]}",
        href: router.group(:'console-function').path(:edit, :'console-route_id' => params[:'console-route_id'], :'console-function_id' => "#{bindable[:plugin]}-#{bindable[:function]}")
      }
    end

    binding :delete_href do
      {
        href: router.group(:'console-function').path(:remove, :'console-route_id' => params[:'console-route_id'], :'console-function_id' => "#{bindable[:plugin]}-#{bindable[:function]}")
      }
    end

    #TODO exclude used functions
    options :availables do
      Pakyow::Console::PluginRegistry.functions.map { |function|
        [function, function]
      }
    end
  end
end

Pakyow::App.routes :'console-settings' do
  include Pakyow::Console::SharedRoutes

  namespace :console, '/console' do
    get :settings, '/settings', before: [:auth], after: [:setup, :notify] do
      items = []
      Pakyow::Console::DataTypeRegistry.types.select(&:display?).select(&:settings?).each do |type|
        items << {
          namespace: "data/#{type.name}",
          nice_name: type.display_name,
          icon_class: type.icon_class,
        }
      end
      
      items.sort! { |a, b| a[:nice_name] <=> b[:nice_name] }
      view.scope(:'console-setting-item').apply(items)
    end
  end
end

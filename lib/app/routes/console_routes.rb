Pakyow::App.routes :console do
  include Pakyow::Console::SharedRoutes

  handler 500 do
    presenter.path = '/console/errors/500'
    response.body << presenter.view.composed.to_html
    halt
  end

  namespace :console, '/console' do
    get :default, '/' do
      reroute router.group(:console).path(:dashboard)
    end

    get :dashboard, '/dashboard', before: [:auth], after: [:setup] do
      view.scope(:app_event).mutate(:list, with: data(:app_event).all).subscribe
    end
  end

  # loads configured routes
  # Pakyow::Console::RouteRegistry.config.each do |route|
  #   self.send(route[:method].downcase.to_sym, route[:name].to_sym, route[:path]) do
  #     begin
  #       presenter.path = route[:view_path]
  #     rescue MissingView
  #     end

  #     catch :halt do
  #       route[:functions].each do |function|
  #         invoke(function[:plugin], function[:function], function[:options])
  #       end
  #     end
  #   end
  # end
end

Pakyow::App.routes :console do
  include Pakyow::Console::SharedRoutes

  namespace :console, '/console' do
    get :default, '/' do
      reroute router.group(:console).path(:dashboard)
    end

    get :dashboard, '/dashboard', before: [:auth], after: [:setup] do
      if using_platform?
        presenter.path = 'console/dashboard-platform'
        view.scope(:app_event).mutate(:list, with: data(:app_event).all).subscribe
      end
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

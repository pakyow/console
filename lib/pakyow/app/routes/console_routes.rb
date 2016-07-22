Pakyow::App.routes :console do
  include Pakyow::Console::SharedRoutes
  
  get 'robots' do
    handle 404 unless req.format == :txt
    send Pakyow::Console.robots.to_s
  end

  namespace :console, '/console' do
    get :default, '/' do
      reroute router.group(:console).path(:dashboard)
    end

    get :dashboard, '/dashboard', before: [:auth], after: [:setup] do
      if using_platform?
        presenter.path = 'console/dashboard-platform'
        # view.scope(:app_event).mutate(:list, with: data(:app_event).all).subscribe
        view.scope(:app_event).mutate(:list, with: []).subscribe
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

Pakyow::App.after :load do
  Pakyow::Router.instance.set :'console-catchall' do
    # This is the catch-all route for mapping to configured endpoints (plugins, pages, etc).
    # Registered in an after hook so it's at the end.
    #
    get /.*/ do
      Pakyow::Console.handle_slug(self)
    end
  end
end

Pakyow::App.after :reload do
  Pakyow::Router.instance.set :'console-catchall' do
    # This is the catch-all route for mapping to configured endpoints (plugins, pages, etc).
    # Registered in an after hook so it's at the end.
    #
    get /.*/ do
      Pakyow::Console.handle_slug(self)
    end
  end
end

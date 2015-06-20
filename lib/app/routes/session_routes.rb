Pakyow::App.routes :session do
  include Pakyow::Console::SharedRoutes

  namespace :console, '/console' do
    get :login, '/login' do
      reroute router.group(:'console-session').path(:new)
    end

    get :logout, '/logout' do
      unauth
      redirect router.group(:console).path(:default)
    end

    restful :'console-session', '/sessions' do
      new do
        redirect router.group(:console).path(:default) if authed?
        redirect router.group(:console).path(:setup) unless setup?

        # setup the form
        view.scope(:'console-session').bind(@session || {})
        handle_errors(view)
      end

      create do
        @session = params[:'console-session']
        if user = Pakyow::Auth::User.authenticate(@session)
          auth(user)
          redirect router.group(:console).path(:default)
        else
          @errors = ['Invalid email and/or password']
          reroute router.group(:'console-session').path(:new), :get
        end
      end
    end
  end
end

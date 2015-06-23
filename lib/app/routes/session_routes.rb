Pakyow::App.routes :session do
  include Pakyow::Console::SharedRoutes

  namespace :console, '/console' do
    get :login, '/login' do
      reroute router.group(:'console-session').path(:new)
    end

    get :platform_login, '/login/platform' do
      if Pakyow.app.env == :development && !platform_creds.empty?
        session[:platform_email] = platform_creds[:email]
        session[:platform_token] = platform_creds[:token]

        setup_platform_socket
        redirect router.group(:console).path(:default)
      else
        presenter.path = 'console/sessions/platform'
        handle_errors(view)
      end
    end

    post '/sessions/platform' do
      if token = PlatformClient.auth(params[:email], params[:password])
        session[:platform_email] = params[:email]
        session[:platform_token] = token

        setup_platform_socket
        redirect router.group(:console).path(:default)
      else
        #TODO handle errors
        redirect router.group(:console).path(:platform_login)
      end
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
          setup_platform_socket
          redirect router.group(:console).path(:default)
        else
          @errors = ['Invalid email and/or password']
          reroute router.group(:'console-session').path(:new), :get
        end
      end
    end
  end
end

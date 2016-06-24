Pakyow::App.routes :'console-session' do
  include Pakyow::Console::SharedRoutes

  namespace :console, '/console' do
    get :login, '/login' do
      reroute router.group(:'console-session').path(:new)
    end

    get :logout, '/logout' do
      console_unauth
      redirect router.group(:console).path(:default)
    end

    restful :'console-session', '/sessions' do
      new do
        redirect router.group(:console).path(:default) if console_authed?

        if console_setup? && platform_token?
          user = Pakyow::Console.model(:user).first(platform_user_id: platform_creds['user_id'])
          # TODO: handle user not found
          console_auth(user)
          redirect router.group(:console).path(:default)
        elsif !console_setup?
          redirect router.group(:console).path(:setup) unless console_setup?
        end

        if using_platform?
          if config.env == :production
            callback_url = File.join(req.base_url, '/console/platform_callback')
            consumer = OAuth::Consumer.new(config.console.platform_key, config.console.platform_secret, site: config.console.platform_url)

            request_token = consumer.get_request_token(oauth_callback: callback_url)

            # TODO: handle OAuth::Unauthorized, Net::HTTPFatalError

            session[:token] = request_token.token
            session[:token_secret] = request_token.secret
            redirect request_token.authorize_url(oauth_callback: callback_url)
          else
            redirect router.group(:console).path(:setup) if using_platform?
          end
        else
          presenter.path = 'console/sessions/new'
        end

        # setup the form
        view.scope(:'console-session').bind(@session || {})
        handle_errors(view)
      end

      create do
        @session = params[:'console-session']
        if user = Pakyow::Console.model(:user).authenticate(@session)
          if user.console?
            console_auth(user)
            setup_platform_socket
            redirect router.group(:console).path(:default)
          else
            console_handle 403
          end
        else
          @errors = ['Invalid login and/or password']
          reroute router.group(:'console-session').path(:new), :get
        end
      end
    end
  end
end

Pakyow::App.routes :'console-setup' do
  include Pakyow::Console::SharedRoutes

  namespace :console, '/console' do
    get '/platform_callback' do
      consumer = OAuth::Consumer.new(config.console.platform_key, config.console.platform_secret, site: config.console.platform_url)

      hash = { oauth_token: session[:token], oauth_token_secret: session[:token_secret]}
      request_token  = OAuth::RequestToken.from_hash(consumer, hash)
      access_token = request_token.get_access_token

      params = access_token.params

      user = Pakyow::Console.model(:user).first(platform_user_id: params[:platform_id])

      if user.nil?
        user = Pakyow::Console.model(:user).new
        user.platform_user_id = params[:platform_id]
        user.consolify
      end

      user.name = params[:platform_name]
      user.email = params[:platform_email]
      user.username = params[:platform_username]
      user.preferred_editor = params[:platform_editor]
      user.platform_token = params[:oauth_token]
      user.platform_token_secret = params[:oauth_token_secret]
      user.save

      console_auth(user)
      setup_platform_socket
      redirect router.group(:console).path(:default)
    end

    get :setup, '/setup' do
      redirect router.group(:console).path(:login) if console_setup? && platform_token?

      if using_platform?
        if config.env == :development
          redirect router.group(:console).path(:setup_platform) if platform_token?
          presenter.path = 'console/setup/token'
        else
          presenter.path = 'console/setup/error'
        end
      else
        presenter.path = 'console/setup/index'
        view.scope(:'pw-user').bind(@user || {})
        handle_errors(view)
      end
    end

    get :setup_platform, '/setup/platform' do

      # TODO: reject access unless in dev mode
      redirect router.group(:console).path(:login) if console_setup?
      redirect router.group(:console).path(:setup) unless platform_token?

      presenter.path = 'console/setup/platform'
      view.scope(:app).apply(platform_client.apps)
    end

    post '/setup/token' do
      # TODO: reject access unless in dev mode
      redirect router.group(:console).path(:login) if console_setup? && platform_token?

      email = params[:email]
      password = params[:password]

      if auth = PlatformClient.auth(params[:email], params[:password])
        user = { email: auth[:user][:email], user_id: auth[:user][:id], token: auth[:access_token][:value] }

        file = File.expand_path('~/.pakyow')
        f = File.open(file, 'w')
        f.write(user.to_json)
        f.close

        # FIXME: move this into a service and use it here and in platform_callback
        user = Pakyow::Console.model(:user).first(platform_user_id: auth[:user][:id])

        if user.nil?
          user = Pakyow::Console.model(:user).new
          user.platform_user_id = auth[:user][:id]
          user.consolify
        end

        user.name = auth[:user][:name]
        user.email = auth[:user][:email]
        user.username = auth[:user][:username]
        user.preferred_editor = auth[:user][:preferred_editor]
        user.save

        console_auth(user)

        redirect router.group(:console).path(:setup_platform)
      else
        #TODO handle failure
      end
    end

    get :setup_app, '/setup/app/:app_id' do
      # TODO: reject access unless in dev mode
      redirect router.group(:console).path(:login) if console_setup?
      redirect router.group(:console).path(:setup_token) unless platform_token?

      if app = platform_client.app(params[:app_id])
        opts = {
          project: {
            id: app[:id]
          }
        }
        f = File.open('./.platform', 'w')
        f.write(opts.to_json)
        f.close

        reconnect_platform_socket(platform_creds)

        session[:platform_email] = platform_creds[:email]
        session[:platform_token] = platform_creds[:token]

        redirect '/console'
      else
        res.status = 404
      end
    end

    post :setup, '/setup' do
      @user = Pakyow::Console.model(:user).new(params[:'pw-user'])
      @user.consolify

      if @user.valid?
        @user.save
        console_auth(@user)

        redirect router.group(:console).path(:feed)
      else
        @errors = @user.errors.full_messages
        reroute router.group(:console).path(:setup), :get
      end
    end
  end
end

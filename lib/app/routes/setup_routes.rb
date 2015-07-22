Pakyow::App.routes :'console-setup' do
  include Pakyow::Console::SharedRoutes

  namespace :console, '/console' do
    get :setup, '/setup' do
      redirect router.group(:console).path(:login) if console_setup?

      if using_platform?
        presenter.path = 'console/setup/index-platform'
      else
        presenter.path = 'console/setup/index'
      end

      # setup the form
      view.scope(:'pw-user').bind(@user || {})
      handle_errors(view)
    end

    get :setup_platform, '/setup/platform' do
      redirect router.group(:console).path(:login) if console_setup?
      redirect router.group(:console).path(:setup_token) unless platform_token?

      view.scope(:app).apply(platform_client.apps)
    end

    get :setup_token, '/setup/token' do
      redirect router.group(:console).path(:login) if console_setup?
      redirect router.group(:console).path(:setup_platform) if platform_token?
    end

    post '/setup/token' do
      redirect router.group(:console).path(:login) if console_setup?
      redirect router.group(:console).path(:setup_platform) if platform_token?

      email = params[:email]
      password = params[:password]

      if token = PlatformClient.auth(params[:email], params[:password])
        auth = { email: email, token: token }
        file = File.expand_path('~/.pakyow')
        f = File.open(file, 'w')
        f.write(auth.to_json)
        f.close

        redirect router.group(:console).path(:setup_platform)
      else
        #TODO handle failure
      end
    end

    get :setup_app, '/setup/app/:app_id' do
      redirect router.group(:console).path(:login) if console_setup?
      redirect router.group(:console).path(:setup_token) unless platform_token?

      if app = platform_client.app(params[:app_id])
        opts = {
          app: {
            id: app[:id]
          }
        }
        f = File.open('./.platform', 'w')
        f.write(opts.to_json)
        f.close
        redirect '/console'
      else
        res.status = 404
      end
    end

    post :setup, '/setup' do
      @user = Pakyow::Console::User.new(params[:'pw-user'])
      @user.role = Pakyow::Console::User::ROLES[:admin]

      if @user.valid?
        @user.save
        console_auth(@user)

        redirect router.group(:console).path(:dashboard)
      else
        @errors = @user.errors
        reroute router.group(:console).path(:setup), :get
      end
    end
  end
end

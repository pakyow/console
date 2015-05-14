Pakyow::App.routes :console do
  fn :auth do
    redirect router.group(:console).path(:login) unless authed?
  end

  fn :setup do
    view.scope(:user).bind(current_user)

    view.partial(:'dev-nav').with do |view|
      if env == :development
        view.scope(:'console-panel-item').apply(Pakyow::Console::PanelRegistry.nav(:development))
      else
        view.remove
      end
    end

    view.partial(:'side-nav').scope(:'console-panel-item').apply(Pakyow::Console::PanelRegistry.nav(:production))
  end

  namespace :console, '/console' do
    get :login, '/login' do
      reroute router.group(:'console-session').path(:new)
    end

    get :logout, '/logout' do
      unauth
      redirect router.group(:console).path(:default)
    end

    get :setup, '/setup' do
      redirect router.group(:console).path(:login) if setup?

      # setup the form
      view.scope(:user).bind(@user || {})
      handle_errors(view)
    end

    post :setup, '/setup' do
      @user = Pakyow::Auth::User.new(params[:user])
      @user.role = Pakyow::Auth::User::ROLES[:admin]

      if @user.valid?
        @user.save
        auth(@user)

        redirect router.group(:console).path(:dashboard)
      else
        @errors = @user.errors
        reroute router.group(:console).path(:setup), :get
      end
    end

    #NOTE while it's tempting to use the auth plugin
    # for this, I don't think that's a great idea.
    #
    # Mainly because there would need to be two configured
    # instances of the same plugin within an app; not
    # sure that's possible or a good idea.
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

    get :default, '/' do
      reroute router.group(:console).path(:dashboard)
    end

    get :dashboard, '/dashboard', before: [:auth], after: [:setup] do
    end
  end

  Pakyow::Console::RouteRegistry.config.each do |route|
    self.send(route[:method].downcase.to_sym, route[:name].to_sym, route[:path]) do
      begin
        presenter.path = route[:view_path]
      rescue MissingView
      end

      catch :halt do
        route[:functions].each do |function|
          invoke(function[:plugin], function[:function], function[:options])
        end
      end
    end
  end
end

Pakyow::App.routes :'console-account' do
  include Pakyow::Console::SharedRoutes

  namespace :console, '/console' do
    get :disconnect, '/platform/disconnect' do
      FileUtils.rm('./.platform')
      redirect '/console'
    end

    get :account, '/account', before: [:auth], after: [:setup, :notify] do
      if platform?
        presenter.path = 'console/account/platform'
      end

      handle_errors(view.partial(:errors), object_type: :user)
      view.scope(:'pw-user').bind(@user || current_console_user)
    end

    post '/account', before: [:auth], after: [:setup, :notify] do
      @user = current_console_user
      @user.set_only(params[:'pw-user'], :name, :username, :email, :password, :password_confirmation)

      if @user.valid?
        @user.save

        notify('account updated', :success, redirect: router.group(:console).path(:account))
      else
        notify('failed to update account', :fail)
        res.status = 400

        @errors = @user.errors.full_messages
        reroute router.group(:console).path(:account), :get
      end
    end
  end
end

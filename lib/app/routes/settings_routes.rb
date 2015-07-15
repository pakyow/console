Pakyow::App.routes :'console-settings' do
  include Pakyow::Console::SharedRoutes

  namespace :console, '/console' do
    get :disconnect, '/platform/disconnect' do
      FileUtils.rm('./.platform')
      redirect '/console'
    end

    get :settings, '/settings', before: [:auth], after: [:setup, :notify] do
      if platform?
        presenter.path = 'console/settings/platform'
      end

      handle_errors(view.partial(:errors), object_type: :user)
      view.scope(:'pw-user').bind(@user || current_console_user)
    end

    post '/settings', before: [:auth], after: [:setup, :notify] do
      @user = current_console_user
      @user.set_only(params[:user], :name, :username, :email, :password, :password_confirmation)

      if @user.valid?
        @user.save

        notify('settings updated', :success, redirect: router.group(:console).path(:settings))
      else
        notify('failed to update settings', :fail)
        res.status = 400

        @errors = @user.errors.full_messages
        reroute router.group(:console).path(:settings), :get
      end
    end
  end
end

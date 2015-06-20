Pakyow::App.routes :settings do
  include Pakyow::Console::SharedRoutes

  namespace :console, '/console' do
    get :disconnect, '/platform/disconnect' do
      FileUtils.rm('./.platform')
      redirect '/console'
    end

    get :settings, '/settings', after: [:setup] do
      if platform?
        presenter.path = 'console/settings/platform'
      end
    end
  end
end

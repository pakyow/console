Pakyow::App.routes :'console-release' do
  include Pakyow::Console::SharedRoutes

  namespace :console, '/console' do
    get :release, '/release', before: [:auth], after: [:setup] do
      if releasable?
        view.scope(:release).mutate(:list, with: data(:release).all).subscribe
      else
        presenter.path = 'console/release/unreleasable'
      end
    end

    get :release_setup, '/release/setup', before: [:auth], after: [:setup] do
      redirect router.group(:console).path(:release) if releasable?
    end

    post '/release/setup/token' do
      redirect router.group(:console).path(:release) if releasable?

      token = params[:token]

      client = heroku_client(token)

      if client.valid?
        auth = { release: { token: token } }
        file = File.expand_path('./.platform-private')
        f = File.open(file, 'w')
        f.write(auth.to_json)
        f.close
        redirect router.group(:console).path(:release)
      else
        #TODO present error message
        redirect router.group(:console).path(:release_setup)
      end
    end

    post '/release', before: [:auth] do
      release = platform_client.create_release
      agent = ReleaseAgent.new(heroku_client, platform_client, release)
      redirect router.group(:console).path(:release)
    end
  end
end

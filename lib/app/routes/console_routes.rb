Pakyow::App.routes :console do
  fn :auth do
    redirect router.group(:console).path(:login) unless authed?
  end

  fn :setup do
    view.scope(:user).bind(current_user)
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

    restful :'console-plugin', '/plugins', after: [:setup] do
      list do
        view.container(:default).scope(:'console-plugin').apply(Pakyow::Console::Plugins.all)
      end

      show do
        plugin = Pakyow::Console::Plugins.find(params[:'console-plugin_id'])

        view.scope(:'console-plugin')[0].bind(plugin)
        # view.scope(:'console-plugin')[1].bind(plugin)

        # if !plugin.mountable
        #   view.partial(:mountable).remove
        # end
      end

      update do
        plugin = Pakyow::Console::Plugins.find(params[:'console-plugin_id'])
        plugin.update(params[:'console-plugin'])

        if plugin.valid?
          plugin.save
          redirect router.group(:'console-plugin').path(:list)
        else
          #TODO handle errors
        end

        #TODO find and update the plugin, writing to plugins.yaml
        #NEXT make it work programatically, then hookup ze ui (possibly do data / pages first)
        #THEN write a simple blog plugin and tie the two together
      end
    end

    restful :'console-route', '/routes', after: [:setup] do
      list do
        view.container(:default).scope(:'console-route').apply(Pakyow::Console::Routes.all) do |view, route|
          if route[:type] == :pakyow
            view.prop(:last_modified).remove
            view.attrs.class.ensure(:internal)
          end
        end
      end

      new do
        view.scope(:'console-route').bind(@route || {})
        handle_errors(view)
      end

      create do
        route_params = params[:'console-route']
        route_params[:author] = current_user

        @route = Pakyow::Console::Route.new(route_params)

        if @route.valid?
          @route.save
          redirect router.group(:'console-route').path(:list)
        else
          @errors = @route.errors
          reroute router.group(:'console-route').path(:new), :get
        end
      end

      edit do
        @route ||= Pakyow::Console::Routes.find(params[:'console-route_id'])

        handle_errors(view)
        view.partial(:form).scope(:'console-route').bind(@route)

        view.partial(:functionality).scope(:'console-function').apply(@route[:functions] || [])
        view.partial(:functionality).scope(:'console-route').prop(:'add-function').attrs.href = router.group(:'console-route').path(:functions, :'console-route_id' => params[:'console-route_id'])
        view.partial(:edit_function).remove
        view.partial(:empty_function).remove
      end

      update do
        route_params = params[:'console-route']
        route_params[:author] = current_user

        @route = Pakyow::Console::Routes.find(params[:'console-route_id'])
        @route.update(route_params)

        if @route.valid?
          @route.save
          redirect router.group(:'console-route').path(:list)
        else
          @errors = @route.errors
          reroute router.group(:'console-route').path(:new), :get
        end
      end

      remove do
        #TODO
      end

      member do
        get :functions, '/functions' do
          presenter.path = 'console/routes/functions'
          presenter.view = view.container(:default)
          view.scope(:'console-function').bind({ availables: nil })
        end
      end

      restful :'console-function', '/functions' do
        create do
          route = Pakyow::Console::Routes.find(params[:'console-route_id'])
          plugin_name, function_name = params[:'console-function'][:availables].split('.')
          plugin = Pakyow::Console::Plugins.find(plugin_name)
          #TODO make sure routes are created with functions
          route[:functions] << {
            plugin: plugin_name,
            function: function_name,
            options: {}
          }
          route.save
          #TODO validate options

          #TODO welp, this is some weirdness
          presenter.path = 'console/routes/edit'
          view.partial(:functionality).scope(:'console-function').apply(route[:functions] || [])
          view.partial(:functionality).scope(:'console-route').prop(:'add-function').attrs.href = router.group(:'console-route').path(:functions, :'console-route_id' => params[:'console-route_id'])
          presenter.view = view.partial(:functionality)
        end

        remove do
          route = Pakyow::Console::Routes.find(params[:'console-route_id'])
          plugin_name, function_name = params[:'console-function_id'].split('-')
          function = route[:functions].find { |function| function[:plugin] == plugin_name && function[:function] == function_name }
          route[:functions].delete(function)
          route.save
          #TODO validate options

          #TODO welp, this is some weirdness
          presenter.path = 'console/routes/edit'
          view.partial(:functionality).scope(:'console-function').apply(route[:functions] || [])
          view.partial(:functionality).scope(:'console-route').prop(:'add-function').attrs.href = router.group(:'console-route').path(:functions, :'console-route_id' => params[:'console-route_id'])
          presenter.view = view.partial(:functionality)
        end

        edit do
          presenter.path = 'console/routes/edit'

          plugin_name, function_name = params[:'console-function_id'].split('-')
          plugin = Pakyow::Console::Plugins.find(plugin_name)
          options = plugin[:functions][function_name.to_sym][:options]

          if options.empty?
            presenter.view = view.partial(:empty_function)
          else
            route = Pakyow::Console::Routes.find(params[:'console-route_id'])
            presenter.view = view.partial(:edit_function)
            function = route[:functions].find { |fn| fn[:plugin] == plugin_name && fn[:function] == function_name }
            view.scope(:'console-function').with do |view|
              view.bind({ id: params[:'console-function_id'] })
              view.scope(:'console-option').repeat(options.keys) do |view, option|
                #TODO humanize name with inflecto
                view.prop(:name)[0].text = option

                view.prop(:name)[1].attrs.value = option
                view.prop(:value).attrs.value = function[:options][option] || options[option]
              end
            end
          end
        end

        update do
          route = Pakyow::Console::Routes.find(params[:'console-route_id'])
          plugin_name, function_name = params[:'console-function_id'].split('-')
          plugin = Pakyow::Console::Plugins.find(plugin_name)
          params[:options].each_with_index do |option, i|
            value = params[:values][i]
            function = route[:functions].find { |fn| fn[:plugin] == plugin_name && fn[:function] == function_name }
            (function[:options] ||= {})[option.to_sym] = value
          end
          route.save
          #TODO validate options
          halt
        end

        # member do
        #   reorder do
        #     #TODO support this
        #   end
        # end
      end
    end
  end

  Pakyow::Console::Routes.config.each do |route|
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

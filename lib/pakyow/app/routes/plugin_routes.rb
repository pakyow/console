Pakyow::App.routes :'console-plugin' do
  include Pakyow::Console::SharedRoutes

  namespace :console, '/console' do
    restful :'console-plugin', '/plugins', after: [:setup] do
      list do
        view.container(:default).scope(:'console-plugin').apply(Pakyow::Console::PluginRegistry.all)
      end

      show do
        plugin = Pakyow::Console::PluginRegistry.find(params[:'console-plugin_id'])

        view.scope(:'console-plugin')[0].bind(plugin)

        view.scope(:'pw-mounted-plugin').apply(Pakyow::Console::Models::MountedPlugin.where(name: plugin.name.to_s).order(Sequel.asc(:slug)).all)
      end

      update do
        plugin = Pakyow::Console::PluginRegistry.find(params[:'console-plugin_id'])
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

      restful :'console-mounted-plugin', '/mounts' do
        new do
          reroute router.group(:datum).path(:new, data_id: 'mount')
        end

        show do
          reroute router.group(:datum).path(:edit, data_id: 'mount', datum_id: params[:'console-mounted-plugin_id'])
        end
      end
    end
  end
end

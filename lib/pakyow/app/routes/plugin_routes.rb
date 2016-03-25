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
        # view.scope(:'console-plugin')[1].bind(plugin)

        # if !plugin.mountable
        #   view.partial(:mountable).remove
        # end
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
    end
  end
end

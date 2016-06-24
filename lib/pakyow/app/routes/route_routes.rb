# Pakyow::App.routes :'console-route' do
#   include Pakyow::Console::SharedRoutes

#   namespace :console, '/console' do
#     #TODO unsure how these need to be defined since it references an after hook
#     # possibly put the hooks in a mixin?
#     restful :'console-route', '/routes', after: [:setup] do
#       list do
#         view.container(:default).scope(:'console-route').apply(Pakyow::Console::RouteRegistry.all) do |view, route|
#           if route[:type] == :pakyow
#             view.prop(:last_modified).remove
#             view.attrs.class.ensure(:internal)
#           end
#         end
#       end

#       new do
#         view.scope(:'console-route').bind(@route || {})
#         handle_errors(view)
#       end

#       create do
#         route_params = params[:'console-route']
#         route_params[:author] = current_user

#         @route = Pakyow::Console::Route.new(route_params)

#         if @route.valid?
#           @route.save
#           redirect router.group(:'console-route').path(:list)
#         else
#           @errors = @route.errors
#           reroute router.group(:'console-route').path(:new), :get
#         end
#       end

#       edit do
#         @route ||= Pakyow::Console::RouteRegistry.find(params[:'console-route_id'])

#         handle_errors(view)
#         view.partial(:form).scope(:'console-route').bind(@route)

#         view.partial(:functionality).scope(:'console-function').apply(@route[:functions] || [])
#         view.partial(:functionality).scope(:'console-route').prop(:'add-function').attrs.href = router.group(:'console-route').path(:functions, :'console-route_id' => params[:'console-route_id'])
#         view.partial(:edit_function).remove
#         view.partial(:empty_function).remove
#       end

#       update do
#         route_params = params[:'console-route']
#         route_params[:author] = current_user

#         @route = Pakyow::Console::RouteRegistry.find(params[:'console-route_id'])
#         @route.update(route_params)

#         if @route.valid?
#           @route.save
#           redirect router.group(:'console-route').path(:list)
#         else
#           @errors = @route.errors
#           reroute router.group(:'console-route').path(:new), :get
#         end
#       end

#       remove do
#         #TODO
#       end

#       member do
#         get :functions, '/functions' do
#           presenter.path = 'console/routes/functions'
#           presenter.view = view.container(:default)
#           view.scope(:'console-function').bind({ availables: nil })
#         end
#       end

#       restful :'console-function', '/functions' do
#         create do
#           route = Pakyow::Console::RouteRegistry.find(params[:'console-route_id'])
#           plugin_name, function_name = params[:'console-function'][:availables].split('.')
#           plugin = Pakyow::Console::PluginRegistry.find(plugin_name)
#           #TODO make sure routes are created with functions
#           route[:functions] << {
#             plugin: plugin_name,
#             function: function_name,
#             options: {}
#           }
#           route.save
#           #TODO validate options

#           #TODO welp, this is some weirdness
#           presenter.path = 'console/routes/edit'
#           view.partial(:functionality).scope(:'console-function').apply(route[:functions] || [])
#           view.partial(:functionality).scope(:'console-route').prop(:'add-function').attrs.href = router.group(:'console-route').path(:functions, :'console-route_id' => params[:'console-route_id'])
#           presenter.view = view.partial(:functionality)
#         end

#         remove do
#           route = Pakyow::Console::RouteRegistry.find(params[:'console-route_id'])
#           plugin_name, function_name = params[:'console-function_id'].split('-')
#           function = route[:functions].find { |function| function[:plugin] == plugin_name && function[:function] == function_name }
#           route[:functions].delete(function)
#           route.save
#           #TODO validate options

#           #TODO welp, this is some weirdness
#           presenter.path = 'console/routes/edit'
#           view.partial(:functionality).scope(:'console-function').apply(route[:functions] || [])
#           view.partial(:functionality).scope(:'console-route').prop(:'add-function').attrs.href = router.group(:'console-route').path(:functions, :'console-route_id' => params[:'console-route_id'])
#           presenter.view = view.partial(:functionality)
#         end

#         edit do
#           presenter.path = 'console/routes/edit'

#           plugin_name, function_name = params[:'console-function_id'].split('-')
#           plugin = Pakyow::Console::PluginRegistry.find(plugin_name)
#           options = plugin[:functions][function_name.to_sym][:options]

#           if options.empty?
#             presenter.view = view.partial(:empty_function)
#           else
#             route = Pakyow::Console::RouteRegistry.find(params[:'console-route_id'])
#             presenter.view = view.partial(:edit_function)
#             function = route[:functions].find { |fn| fn[:plugin] == plugin_name && fn[:function] == function_name }
#             view.scope(:'console-function').with do |view|
#               view.bind({ id: params[:'console-function_id'] })
#               view.scope(:'console-option').repeat(options.keys) do |view, option|
#                 #TODO humanize name with inflecto
#                 view.prop(:name)[0].text = option

#                 view.prop(:name)[1].attrs.value = option
#                 view.prop(:value).attrs.value = function[:options][option] || options[option]
#               end
#             end
#           end
#         end

#         update do
#           route = Pakyow::Console::RouteRegistry.find(params[:'console-route_id'])
#           plugin_name, function_name = params[:'console-function_id'].split('-')
#           plugin = Pakyow::Console::PluginRegistry.find(plugin_name)
#           params[:options].each_with_index do |option, i|
#             value = params[:values][i]
#             function = route[:functions].find { |fn| fn[:plugin] == plugin_name && fn[:function] == function_name }
#             (function[:options] ||= {})[option.to_sym] = value
#           end
#           route.save
#           #TODO validate options
#           halt
#         end

#         # member do
#         #   reorder do
#         #     #TODO support this
#         #   end
#         # end
#       end
#     end
#   end
# end

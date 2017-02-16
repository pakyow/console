# module Pakyow
#   module Console
#     module Models
#       class MountedPlugin < Sequel::Model(:'pw-mounted-plugins')
#       end
#     end
#   end
# end
#
# # TODO: move these to a more logical place
# Pakyow::Console.after :mount, :edit do
#   path_parts = req.first_path.split('/')
#
#   if path_parts[2] == 'plugins'
#     view.scope(:'console-datum').prop(:name).attrs.disabled = true
#
#     view.scope(:'console-data-type').with do |view|
#       view.prop(:'show-href').attrs.href = router.group(:'console-plugin').path(:show, :'console-plugin_id' => path_parts[3])
#       view.prop(:'back-text').text = 'Plugin'
#     end
#   end
# end
#
# Pakyow::Console.before :mount, :new do
#   @datum = Pakyow::Console::Models::MountedPlugin.new
#   @datum.name = req.first_path.split('/')[3]
# end
#
# Pakyow::Console.after :mount, :new do
#   path_parts = req.first_path.split('/')
#
#   if path_parts[2] == 'plugins'
#     view.scope(:'console-datum').prop(:name).attrs.disabled = true
#
#     view.scope(:'console-data-type').with do |view|
#       view.prop(:'show-href').attrs.href = router.group(:'console-plugin').path(:show, :'console-plugin_id' => path_parts[3])
#       view.prop(:'back-text').text = 'Plugin'
#     end
#   end
# end
#
# Pakyow::Console.after :mount, :create do
#   Pakyow::Console.mount_plugins(Pakyow.app)
# end
#
# Pakyow::Console.after :mount, :update do
#   Pakyow::Console.mount_plugins(Pakyow.app)
# end
#
# Pakyow::Console.after :mount, :delete do
#   Pakyow::Console.mount_plugins(Pakyow.app)
# end

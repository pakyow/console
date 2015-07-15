task :compile do
  require 'sass/plugin'

  res_path = './lib/resources/console'
  Sass::Plugin.add_template_location(File.join(res_path, 'scss'), File.join(res_path, 'styles'))
  Sass::Plugin.update_stylesheets
end

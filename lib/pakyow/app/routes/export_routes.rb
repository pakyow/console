Pakyow::App.routes :'console-export' do
  include Pakyow::Console::SharedRoutes

  namespace :console, '/console' do
    restful :export, '/export' do
      create before: [:auth] do
        platform_client.create_site_export
        notify("export started", :success)
        redirect "/console/data/export"
      end
    end
  end
end

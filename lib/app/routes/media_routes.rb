Pakyow::App.routes :'console-media' do
  include Pakyow::Console::SharedRoutes

  namespace :console, '/console' do
    restful :media, '/media' do
      default do
        view.scope(:file).mutate(:list, with: data(:file).all_of_type(:image)).subscribe
      end
    end
  end
end

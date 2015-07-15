Pakyow::App.routes :'console-file' do
  include Pakyow::Console::SharedRoutes

  namespace :console, '/console' do
    restful :file, '/files' do
      show do
        if file = Pakyow::Console::FileStore.instance.find(params[:file_id])
          w = params[:w]
          h = params[:h]

          if w && h && file[:type] == 'image'
            file = Pakyow::Console::FileStore.instance.process(params[:file_id], w: w, h: h)
          else
            file = File.open(file[:path])
          end

          send(file)
        else
          handle 404
        end
      end
    end
  end
end

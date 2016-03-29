Pakyow::App.routes :'console-file' do
  include Pakyow::Console::SharedRoutes

  namespace :console, '/console' do
    restful :file, '/files' do
      create before: [:auth] do
        name = request.env['HTTP_X_FILENAME']
        file = request.env['rack.input']

        # this works around a presumable bug in rack where a file
        # upload via ajax is sometimes a Tempfile object and
        # sometimes a StringIO object
        if file.is_a?(StringIO)
          tmp = Tempfile.new(name)
          tmp.binmode
          tmp.write(file.string)
          file = tmp
        end

        data(:file).create(name, file)
      end

      show do
        if file = Pakyow::Console::FileStore.instance.find(params[:file_id])
          w = params[:w]
          h = params[:h]
          m = params[:m]

          if w && h && file[:type] == 'image'
            data = Pakyow::Console::FileStore.instance.processed(params[:file_id], w: w, h: h, m: m)
          else
            data = Pakyow::Console::FileStore.instance.data(params[:file_id])
          end

          send(data, Rack::Mime.mime_type(file[:ext]))
        else
          handle 404
        end
      end
    end
  end
end

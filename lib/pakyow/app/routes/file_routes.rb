Pakyow::App.routes :'console-file' do
  include Pakyow::Console::SharedRoutes

  namespace :console, '/console' do
    restful :file, '/files' do
      create before: [:auth] do
        name = request.env['HTTP_X_FILENAME']
        file = request.env['rack.input']

        # this works around a presumable bug in rack where a file
        # upload via ajax is sometimes a Tempfile object and
        # sometimes an io object
        if file.respond_to?(:read)
          tmp = Tempfile.new(name)
          tmp.binmode
          tmp.write(file.read)
          file = tmp
        end

        # TODO: this isn't auto-updating for some reason (at least locally)
        data(:file).create(name, file)
      end

      show do
        if file = Pakyow::Console::FileStore.instance.find(params[:file_id])
          w = params[:w]
          h = params[:h]
          m = params[:m]

          if w && h && file[:type] == 'image'
            data = Pakyow::Console::FileStore.instance.processed(params[:file_id], w: w, h: h, m: m, request_context: self)
          else
            data = Pakyow::Console::FileStore.instance.data(params[:file_id], request_context: self)
          end

          send(data, Rack::Mime.mime_type(file[:ext]))
        else
          handle 404
        end
      end
    end
  end
end

Pakyow::App.mutators :file do
  mutator :list do |view, data|
    view.apply(data) do |datum|
      id = datum[:id]

      config = {
        id: id,
        thumb: Pakyow.app.router.group(:file).path(:show, file_id: id)
      }

      attrs.send(:'data-config=', config.map { |c| c.join(':') }.join(';'))
    end
  end
end

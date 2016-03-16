Pakyow::App.mutators :collaborator do
  mutator :list do |view, data|
    view.apply(data) do |view, datum|
      view.attrs.title = datum[:name]

      if datum[:online]
        view.attrs.class.deny(:offline)
      else
        view.attrs.class.ensure(:offline)
      end
    end
  end
end

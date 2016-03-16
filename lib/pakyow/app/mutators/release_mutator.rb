Pakyow::App.mutators :release do
  mutator :list do |view, data|
    view.apply(data) do |view, datum|
      view.scope(:collaborator).bind(datum[:user])
    end
  end
end

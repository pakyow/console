Pakyow::App.mutators :app_event do
  mutator :list do |view, data|
    view.apply(data) do |view, datum|
      view.scope(:collaborator).bind(datum[:user])
    end
  end
end

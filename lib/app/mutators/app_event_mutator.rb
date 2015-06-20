Pakyow::App.mutators :app_event do
  mutator :list do |view, data|
    view.apply(data)
  end
end

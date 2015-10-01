Pakyow::App.mutators :file do
  mutator :list do |view, data|
    view.apply(data)
  end
end

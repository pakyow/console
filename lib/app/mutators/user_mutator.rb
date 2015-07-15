Pakyow::App.mutators :'pw-user' do
  mutator :list do |view, users|
    view.apply(users)
  end

  mutator :count do |view, count|
    view.prop(:count).text = count
  end
end

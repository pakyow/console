Pakyow::App.mutable :user do
  query :all do
    Pakyow::Console::User.all
  end
end

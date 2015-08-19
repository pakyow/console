Pakyow::App.mutable :user do
  query :all do
    Pakyow::Console.model(:user).all
  end
end

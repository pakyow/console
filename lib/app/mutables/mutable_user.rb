Pakyow::App.mutable :user do
  query :all do
    Pakyow::Auth::User.all
  end
end

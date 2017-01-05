Pakyow::App.mutable :collaborator do
  query :all do
    Pakyow::Console::Models::PlatformUser.all(platform_client)
  end

  action :mutated do |params|
    # no-op
  end
end

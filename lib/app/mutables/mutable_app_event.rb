Pakyow::App.mutable :app_event do
  query :all do
    platform_client.events
  end

  action :create do |params|
    # no-op
  end
end

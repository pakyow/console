Pakyow::App.mutable :release do
  query :all do
    platform_client.releases
  end

  action :mutated do |params|
    # no-op
  end
end

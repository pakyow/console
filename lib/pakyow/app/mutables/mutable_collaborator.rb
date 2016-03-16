Pakyow::App.mutable :collaborator do
  query :all do
    platform_client.collaborators
  end

  action :mutated do |params|
    # no-op
  end
end

Pakyow::App.mutable :errors do
  query :all do
    context.errors || []
  end

  action :mutated do |params|
    # no-op
  end
end

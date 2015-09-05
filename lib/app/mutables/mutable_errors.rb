Pakyow::App.mutable :errors do
  query :all do
    {
      object_type: context.error_object_type,
      errors: context.errors || []
    }

  end

  action :mutated do |params|
    # no-op
  end
end

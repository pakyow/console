Pakyow::App.mutable :datum do
  query :all do |klass, value|
    {
      type: klass,
      value: value,
      data: Object.const_get(klass).all
    }

  end

  action :mutated do |params|
    # no-op
  end
end

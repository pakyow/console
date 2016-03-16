Pakyow::App.mutable :datum do
  query :for_relation do |related_type, related_name, datum_type, datum_id|
    related_class = Object.const_get(related_type)
    datum_class = Object.const_get(datum_type)

    {
      related_class: related_class,
      related_name: related_name,
      datum: datum_class[datum_id],
      data: related_class.all
    }

  end

  action :mutated do |params|
    # no-op
  end
end

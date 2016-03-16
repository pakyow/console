Pakyow::App.mutators :datum do
  mutator :list_relations, qualify: [:related_class, :related_name] do |view, object|
    html = '<option value="">choose...</option>'

    object[:data].each do |datum|
      related_datum = object[:datum].nil? ? nil : object[:datum].send(object[:related_name])

      if related_datum && related_datum.id == datum.id
        selected = ' selected'
      else
        selected = ''
      end

      html << '<option value="' + datum.class.name + '__' + datum.id.to_s + '"' + selected + '>' + datum.relation_name + '</option>'
    end

    view.html = html
    view
  end
end

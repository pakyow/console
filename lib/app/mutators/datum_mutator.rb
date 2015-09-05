Pakyow::App.mutators :datum do
  mutator :list_relations, qualify: [:type] do |view, object|
    html = '<option value="">choose...</option>'

    object[:data].each do |datum|
      if object[:value] == datum.id
        selected = ' selected'
      else
        selected = ''
      end

      html << '<option value="' + datum.class.name + ':' + datum.id.to_s + '"' + selected + '>' + datum.relation_name + '</option>'
    end

    view.html = html
    view
  end
end

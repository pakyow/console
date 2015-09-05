Pakyow::Console::EditorRegistry.register :relation do |options, datum, attribute|
  view = Pakyow::Presenter::ViewContext.new(presenter.store(:console).partial('console/editors', :relation).dup, self)
  view.scoped_as = :datum

  view.component(:modal).attrs.href = router.group(:data).path(:show, data_id: attribute[:name])

  value = datum ? datum.id : nil

  view.mutate(:list_relations, with: data(:datum).all(attribute[:extras][:class], value)).subscribe
  view.instance_variable_get(:@view)
end

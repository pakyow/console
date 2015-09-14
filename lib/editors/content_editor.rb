Pakyow::Console::EditorRegistry.register :content do
  partial = presenter.store(:console).partial('console/editors', :content).dup

  partial.includes({
    shared: presenter.store(:console).partial('console/editors', :shared).dup,
    actions: presenter.store(:console).partial('console/editors', :actions).dup,
    alignment: presenter.store(:console).partial('console/editors', :alignment).dup
  })

  view = Pakyow::Presenter::ViewContext.new(partial, self)
  view.instance_variable_get(:@view)
end

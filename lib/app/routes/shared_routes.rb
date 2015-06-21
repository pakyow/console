module Pakyow::Console::SharedRoutes
  include Pakyow::Routes

  fn :auth do
    redirect router.group(:console).path(:login) unless authed?
  end

  fn :setup do
    view.partial(:'dev-nav').with do |view|
      if env == :development
        view.scope(:'console-panel-item').apply(Pakyow::Console::PanelRegistry.nav(:development))
      else
        view.remove
      end
    end

    view.partial(:'side-nav').scope(:'console-panel-item').apply(Pakyow::Console::PanelRegistry.nav(:production))

    setup_toolbar(view)
  end

  fn :notify do
    if notify = session[:notify]
      view.component(:notifier).with do |view|
        view.text = notify[:message]
        view.attrs.class.deny :hide
        view.attrs.class.ensure notify[:type]
        session[:notify] = nil
      end
    end
  end
end

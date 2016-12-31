module Pakyow::Console::SharedRoutes
  include Pakyow::Routes

  fn :auth do
    redirect router.group(:console).path(:setup) unless console_setup?
    redirect router.group(:console).path(:login) unless console_authed?
  end

  fn :setup do
    items = Pakyow::Console::PanelRegistry.nav

    # add custom data types
    Pakyow::Console::DataTypeRegistry.types.select(&:display?).reject(&:settings?).each do |type|
      items << {
        namespace: "data/#{type.name}",
        nice_name: type.display_name,
        icon_class: type.icon_class,
      }
    end

    items.sort! { |a, b| a[:nice_name] <=> b[:nice_name] }
    discover = items.find { |item| item[:nice_name] == "Discover" }
    items.delete(discover)
    items.unshift(discover)

    view.scope(:'console-panel-item').apply(items) do |view, item|
      if req.first_path.include?("/console/#{item[:namespace]}")
        view.attrs.class.ensure(:active)
      end
    end

    setup_toolbar(view)
    mixin_scripts(view)
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

  fn :prepare_project do
    begin
      view.scope(:'pw-project').bind({ name: config.app.name })
    rescue Pakyow::Presenter::MissingView
    end
  end
end

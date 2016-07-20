# make sure this after configure block executes first
# TODO: need an api for this on Pakyow::App
Pakyow::App.hook(:after, :configure).unshift(lambda  {
  Pakyow::Console.setup_db
  config.app.uri = ENV['APP_URI']
})

Pakyow::App.after :init do
  if Pakyow::Config.env == :development
    if info = platform_creds
      @context = Pakyow::AppContext.new
      setup_platform_socket(info)
    end
  end
end

Pakyow::App.hook(:before, :error).unshift(lambda {
  next unless req.path_parts.first == 'console'
  logger.error "[500] #{req.error.class}: #{req.error}\n" + req.error.backtrace.join("\n") + "\n\n"
  console_handle 500
})

Pakyow::App.after :match do
  # this guard is needed because the route hooks are called again when calling a handler :/
  # TODO: think through a fix for the above
  if !@console_404 && Pakyow::Console::Models::InvalidPath.invalid_for_path?(req.path)
    @console_404 = true
    handle 404, false
  end

  page = Pakyow::Console.pages.find { |p| p.matches?(req.path) }
  next if page.nil?

  # TODO: we can't reroute, but we could fetch and call the show page route

  if !@console_404 && !page.published
    @console_404 = true
    handle 404, false
  end

  if page.fully_editable?
    template = presenter.store(:default).template(page.template.to_sym)
    presenter.view = template.build(page).includes(presenter.store(:default).partials('/'))
    presenter.view.title = String.presentable(page.name)
    view = presenter.view
  else
    view = presenter.view.composed
  end

  renderer_view = presenter.store(:console).view('/console/pages/template')

  Pakyow::Console::Models::Page.editables_for_view(view).each do |editable|
    content = page.content_for(editable[:doc].get_attribute(:'data-editable'))
    parts = editable[:doc].editable_parts

    if parts.empty? || editable[:doc].has_attribute?(:'data-editable-unrestrict')
      rendered = renderer_view.scope(:content)[0].dup
      html = Pakyow::Console::ContentRenderer.render(content.content, view: rendered, constraints: editable[:constraints]).to_html
      editable[:doc].clear
      editable[:doc].append(html)
    else
      editable[:doc].editable_parts.each_with_index do |part, i|
        rendered = renderer_view.scope(:content)[0].dup

        html = Pakyow::Console::ContentRenderer.render([content.content[i]], view: rendered, constraints: editable[:constraints]).to_html
        part[:doc].replace(html)
      end
    end
  end
end

Pakyow::App.after :process do
  if @presenter && @presenter.presented? && res.body && res.body.is_a?(Array)
    render_toolbar
  end
end

Pakyow::App.before :load do
  Pakyow::Console.boot_plugins

  unless @paths_loaded
    Pakyow::Console.load_paths.each do |path|
      Pakyow::Console.loader.load_from_path(path)
    end
  end

  @paths_loaded = true
end

Pakyow::App.after :load do
  Pakyow::Console.load
end

Pakyow::App.after :route do
  if !found? && req.path_parts[0] == 'console'
    console_handle 404
  end
end

Pakyow::App.after :load do
  Pakyow::Console.mount_plugins(self, loading: true)
end

Pakyow::App.after :reload do
  Pakyow::Console.mount_plugins(self, loading: true)
end

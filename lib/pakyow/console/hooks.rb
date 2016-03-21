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
  # TODO: this guard is needed because the route hooks are called again when calling a handler :/
  if !@console_404 && Pakyow::Console::Models::InvalidPath.invalid_for_path?(req.path)
    @console_404 = true
    handle 404, false
  end

  page = Pakyow::Console.pages.find { |p| p.matches?(req.path) }
  next if page.nil?

  if !@console_404 && !page.published
    @console_404 = true
    handle 404, false
  end

  if page.fully_editable?
    template = presenter.store(:default).template(page.template.to_sym)
    presenter.view = template.build(page).includes(presenter.store(:default).partials('/'))
    presenter.view.title = String.presentable(page.name)
  else
    renderer_view = presenter.store(:console).view('/console/pages/template')
    presenter.view.composed.doc.editables.each do |editable|
      content = page.content_for(editable[:doc].get_attribute(:'data-editable'))
      parts = editable[:doc].editable_parts

      if parts.empty?
        rendered = renderer_view.scope(:content)[0].dup
        Pakyow::Console::ContentRenderer.render(content.content, view: rendered)
        editable[:doc].clear
        editable[:doc].append(rendered.to_html)
      else
        editable[:doc].editable_parts.each_with_index do |part, i|
          rendered = renderer_view.scope(:content)[0].dup

          Pakyow::Console::ContentRenderer.render([content.content[i]], view: rendered, constraints: page.constraints)
          part[:doc].replace(rendered.to_html)
        end
      end
    end
  end
end

Pakyow::App.after :process do
  if req.path_parts[0] != 'console' && @presenter && @presenter.presented? && console_authed? && res.body && res.body.is_a?(Array)
    view = Pakyow::Presenter::ViewContext.new(Pakyow::Presenter::View.new(File.open(File.join(Pakyow::Console::ROOT, 'views', 'console', '_toolbar.slim')).read, format: :slim), self)
    setup_toolbar(view)

    console_css = '<link href="/console/styles/console-toolbar.css" rel="stylesheet" type="text/css">'

    if config.assets.compile_on_startup
      console_css = Pakyow::Assets.mixin_fingerprints(console_css)
    end

    font_css = '<link href="//fonts.googleapis.com/css?family=Open+Sans:400italic,400,300,600,700" rel="stylesheet" type="text/css">'
    fa_css = '<link rel="stylesheet" href="//maxcdn.bootstrapcdn.com/font-awesome/4.3.0/css/font-awesome.min.css">'

    body = res.body[0]
    body.gsub!(Pakyow::Console::CLOSING_HEAD_REGEX, console_css + font_css + fa_css + '</head>')
    body.gsub!(Pakyow::Console::CLOSING_BODY_REGEX, view.to_html + '</body>')
  end
end

Pakyow::App.before :load do
  Pakyow::Console.boot_plugins
end

Pakyow::App.after :load do
  Pakyow::Console.load
end

Pakyow::App.after :route do
  if !found? && req.path_parts[0] == 'console'
    console_handle 404
  end
end

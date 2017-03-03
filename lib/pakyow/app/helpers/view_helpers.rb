module Pakyow::Helpers
  def errors
    @errors
  end

  def handle_errors(view, object_type: nil, object_id: nil)
    q = {
      object_type: object_type,
      object_id: object_id,
    }

    unless current_console_user.nil?
      q[:user_id] = current_console_user[:id]
    end

    if req.socket? && @errors && !@errors.empty?
      ui.mutated(:errors, q)
    else
      view.scope(:errors).mutate(:list, with: data(:errors).all).subscribe(q)
    end
  end

  def gravatar_url(hash)
    if Pakyow::Config.env == :development
      d = 'retro'
    else
      # d = CGI::escape("http://#{request.env['HTTP_HOST']}/images/avatar-default.png")
      d = 'retro'
    end

    "//gravatar.com/avatar/#{hash}?d=#{d}"
  end

  #TODO move this somewhere else
  def invoke(plugin, function, options = {})
    #TODO mixin default option values
    Pakyow::Console::PluginRegistry.find(plugin).invoke(function, self, options)
  end

  def render_toolbar
    if console_authed?
      view = Pakyow::Presenter::ViewContext.new(Pakyow::Presenter::View.new(File.open(File.join(Pakyow::Console::ROOT, 'views', 'console', '_toolbar.slim')).read, format: :slim), self)
      setup_toolbar(view)

      console_css = '<link href="/console/styles/console-toolbar.css" rel="stylesheet" type="text/css">'

      if config.env == :production
        console_css = Pakyow::Assets.mixin_fingerprints(console_css)
      end

      font_css = '<link href="//fonts.googleapis.com/css?family=Open+Sans:400italic,400,300,600,700" rel="stylesheet" type="text/css">'
      fa_css = '<link rel="stylesheet" href="//maxcdn.bootstrapcdn.com/font-awesome/4.3.0/css/font-awesome.min.css">'

      body = res.body[0]
      body.gsub!(Pakyow::Console::CLOSING_HEAD_REGEX, console_css + font_css + fa_css + '</head>')
      body.gsub!(Pakyow::Console::CLOSING_BODY_REGEX, view.to_html + '</body>')
    end
  end

  def setup_toolbar(view)
    begin
      view = view.partial(:toolbar)
    rescue NoMethodError
    end

    view.scope(:'pw-user').bind(current_console_user)
    view.scope(:collaborator).mutate(:list, with: data(:collaborator).all).subscribe
  end
  
  def setup_platform_embed(view)
    return unless platform?
    
    doc = Oga.parse_html(platform_client.embed)
    view.scope(:head).append(Pakyow::Presenter::View.new(doc.css("link")[0].to_xml))
    embed = Pakyow::Presenter::View.new(doc.css("header")[0].to_xml)
    view.scope(:embed).append(embed)
  end

  def mixin_scripts(view)
    Pakyow::Console::ScriptRegistry.scripts.each do |path|
      view.scope(:head).append(Pakyow::Presenter::View.new('<script src="' + path + '"></script>'))
    end
  end

  def mixin_view(path, store_name)
    if store(:default).at?(path)
      includes = store(store_name).partials(path).merge(store(:default).partials(path))
      presenter.view = store(:default).composer(path, includes: includes)
    else
      includes = store(store_name).partials(path).merge(store(:default).partials('/'))
      template = store(:default).template(:default)
      presenter.view = Pakyow::Presenter::ViewComposer.new(store(store_name), path, { template: template, includes: includes })
    end
  end
end

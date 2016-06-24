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

  def setup_toolbar(view)
    begin
      view = view.partial(:toolbar)
    rescue NoMethodError
    end

    view.scope(:'pw-user').bind(current_console_user)

    # collaborator presence
    if Pakyow::Config.env == :development
      # TODO: revisit this b/c performance implications
      # view.scope(:collaborator).mutate(:list, with: data(:collaborator).all).subscribe
    end
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

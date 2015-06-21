module Pakyow::Helpers
  def handle_errors(view, object_type: nil, object_id: nil)
    q = {
      object_type: object_type,
      object_id: object_id,
    }

    unless current_user.nil?
      q[:user_id] = current_user.id
    end

    if req.socket? && @errors && !@errors.empty?
      ui.mutated(:errors, data: @errors, qualify: q)
    else
      view.scope(:errors).mutate(:list, data: @errors).subscribe(q)
    end
  end

  def gravatar_url(hash)
    if Pakyow.app.env == :development
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
    view.scope(:'console-user').bind(current_user)

    # collaborator presence
    view.scope(:collaborator).mutate(:list, with: data(:collaborator).all).subscribe
  end
end

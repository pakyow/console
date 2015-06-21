Pakyow::App.bindings :'console-user' do
  scope :'console-user' do
    binding :'avatar-small' do
      if bindable.is_a?(Hash)
        g_hash = Digest::MD5.hexdigest(bindable[:email])
      else
        g_hash = bindable.gravatar_hash
      end

      {
        src: gravatar_url(g_hash)
      }
    end
  end
end

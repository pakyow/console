Pakyow::App.bindings :'console-user' do
  scope :'console-user' do
    binding :'avatar-small' do
      {
        src: gravatar_url(bindable.gravatar_hash)
      }
    end
  end
end

Pakyow::App.bindings :collaborator do
  scope :collaborator do
    binding :'avatar-small' do
      {
        src: gravatar_url(Digest::MD5.hexdigest(bindable[:email]))
      }
    end
  end
end

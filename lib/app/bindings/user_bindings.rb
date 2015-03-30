Pakyow::App.bindings :user do
  scope :user do
    restful :user

    binding :'avatar-small' do
      {
        src: gravatar_url(bindable.gravatar_hash)
      }
    end
  end
end

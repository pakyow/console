Pakyow::App.bindings :'pw-user' do
  scope :'pw-user' do
    restful :'pw-user'

    binding :'edit-href' do
      { href: router.group(:datum).path(:edit, data_id: 'user', datum_id: bindable.id) }
    end

    binding :role do
      {
        content: bindable[:role],
        class: lambda { |c| c.ensure(bindable[:role])}
      }
    end

    binding :'avatar-small' do
      {
        src: gravatar_url(Digest::MD5.hexdigest(bindable[:email]))
      }
    end
    
    binding :'description' do
      if bindable.is_a?(Pakyow::Console::Models::PlatformUser)
        # TODO: don't build html here :/
        if bindable.type == :user
          desc = "<span class=\"user-name\">#{bindable.name}</span>"
          if bindable.username
            desc << "<span class=\"user-aka\">aka</span><span class=\"user-username\">#{bindable.username}</span>"
          end
          desc
        elsif bindable.type == :invite
          "Invited"
        end
      else
        # TODO: implement this
      end
    end
  end
end

Pakyow::App.bindings :'console-route' do
  scope :'console-route' do
    restful :'console-route'

    binding :author do
      if bindable[:type] == :pakyow
        {
          src: '/console/images/pakyow.png',
          title: 'Pakyow'
        }
      else
        {
          src: gravatar_url(bindable[:author][:gravatar])
        }
      end
    end

    binding :last_modified do
      if bindable[:type] == :console
        bindable[:last_modified].strftime('%b %d, %Y at %H:%M%p')
      end
    end

    binding :'edit-href' do
      if bindable[:type] == :console
        { href: router.group(:'console-route').path(:edit, :'console-route_id' => bindable[:id]) }
      else
        { view: lambda { |view| view.prop(:'edit-href').remove } }
      end
    end
  end
end

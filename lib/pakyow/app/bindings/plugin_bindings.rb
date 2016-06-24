Pakyow::App.bindings :'console-plugin' do
  scope :'console-plugin' do
    restful :'console-plugin'

    binding :version do
      "(v#{bindable[:version]})"
    end

    binding :'show-href' do
      { href: router.group(:'console-plugin').path(:show, :'console-plugin_id' => bindable.name) }
    end

    binding :readme do |value|
      Pakyow.app.presenter.processor_store[:md].call(value)
    end

    binding :'new-mount-link' do
      part :href do
        router.group(:'console-mounted-plugin').path(:new, :'console-plugin_id' => bindable.name)
      end
    end
  end

  scope :'pw-mounted-plugin' do
    binding :active do
      part :class do |value|
        if bindable.active
          value.ensure(:active)
        else
          value.deny(:active)
        end
      end
    end

    binding :'edit-href' do
      part :href do
        router.group(:'console-mounted-plugin').path(:show, :'console-plugin_id' => bindable.name, :'console-mounted-plugin_id' => bindable.id)
      end
    end

    binding :'full-slug' do
      File.join(config.app.uri, bindable.slug)
    end
  end
end

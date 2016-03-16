Pakyow::App.bindings :'console-data-type' do
  scope :'console-data-type' do
    binding :'show-link' do
      {
        content: bindable.display_name,
        href: router.group(:data).path(:show, data_id: bindable.id)
      }
    end

    binding :'show-href' do
      {
        href: router.group(:data).path(:show, data_id: bindable.id)
      }
    end

    binding :'back-text' do
      "All #{bindable.display_name}"
    end

    binding :'new-href' do
      {
        href: router.group(:datum).path(:new, :data_id => bindable.id)
      }
    end

    binding :'new-text' do
      "New #{bindable.nice_name}"
    end
  end

  scope :'console-data-field' do
    binding :nice_name do
      bindable[:nice]
    end
  end

  scope :'console-datum' do
    restful :datum

    binding :'edit-href' do
      {
        href: router.group(:datum).path(:edit, data_id: params[:data_id], datum_id: bindable.id)
      }
    end

    binding :'delete-href' do
      {
        href: router.group(:datum).path(:remove, data_id: params[:data_id], datum_id: bindable.id)
      }
    end
  end
end

Pakyow::App.bindings :'console-data-type' do
  scope :'console-data-type' do
    binding :'show-link' do
      {
        #TODO humanize
        content: bindable[:name],
        href: router.group(:'console-data').path(:show, :'console-data_id' => bindable[:id])
      }
    end
  end
end

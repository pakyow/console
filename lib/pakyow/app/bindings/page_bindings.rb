Pakyow::App.bindings :'pw-page' do
  scope :'pw-page' do
    binding :published_at do
      part :content do
        if bindable.published?
          bindable.updated_at.strftime('%e %b %Y').strip
        else
          "unpublished"
        end
      end
    end

    binding :'edit-href' do
      { href: router.group(:datum).path(:edit, data_id: 'page', datum_id: bindable.id) }
    end
  end
end

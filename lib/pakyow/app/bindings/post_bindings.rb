Pakyow::App.bindings :'pw-post' do
  scope :'pw-post' do
    binding :'show-link' do
      part :href do
        File.join('/', context.current_collection.slug, bindable.slug)
      end

      part :content do
        bindable.title
      end
    end
    
    binding :"internal-show-link" do
      part :href do
        "/console/data/post/datum/#{bindable.id}/edit"
      end
      
      part :content do
        bindable.title
      end
    end

    binding :permalink do
      part :href do
        File.join('/', bindable.slug)
      end

      part :content do
        bindable.published_at.strftime('%e %b %Y').strip
      end
    end
    
    binding :permalink_href do
      part :href do
        File.join('/', bindable.slug)
      end
    end

    binding :published_at do |value|
      part :content do
        if bindable.published?
          value.strftime('%e %b %Y').strip
        else
          "unpublished"
        end
      end
    end

    binding :author do
      part :content do
        bindable.user.username if bindable.user
      end
    end
    
    binding :"rendered-summary" do
      part :view do |view|
        view.replace(bindable.summary_html)
      end
    end
    
    binding :'edit-href' do
      { href: router.group(:datum).path(:edit, data_id: 'post', datum_id: bindable.id) }
    end
    
    binding :avatar do
      if bindable.user
        { { src: gravatar_url(Digest::MD5.hexdigest(bindable.user[:email])) } }
      else
        { { src: gravatar_url(Digest::MD5.hexdigest("support@pakyow.com")) } }
      end
    end
  end
end

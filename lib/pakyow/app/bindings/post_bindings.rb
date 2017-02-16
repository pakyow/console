Pakyow::App.bindings :'pw-post' do
  scope :'pw-post' do
    binding :'show-link' do
      part :href do
        if context.current_collection
          File.join('/', context.current_collection.slug, bindable.slug)
        else
          File.join('/', bindable.slug)
        end
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
        if bindable.is_a?(Pakyow::Console::Models::SyndicatedPost)
          File.join(bindable.site_url, bindable.slug)
        else
          File.join('/', bindable.slug)
        end
      end
    end

    binding :feed_href do
      part :href do
        if bindable.is_a?(Pakyow::Console::Models::SyndicatedPost)
          "/console/dashboard/post/#{bindable.post_id}"
        else
          "/console/dashboard/post/#{bindable.id}"
        end
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
        if bindable.is_a?(Pakyow::Console::Models::Post)
          bindable.user.username if bindable.user
        end
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
      if bindable.is_a?(Pakyow::Console::Models::SyndicatedPost)
        { src: gravatar_url(bindable.gravatar) }
      else
        if bindable.user
          { src: gravatar_url(Digest::MD5.hexdigest(bindable.user[:email])) }
        else
          { src: gravatar_url(Digest::MD5.hexdigest("support@pakyow.com")) }
        end
      end
    end

    binding :subscribe do
      if bindable.is_a?(Pakyow::Console::Models::SyndicatedPost)
        if Pakyow::Console::Models::Subscription.first(project_id: bindable.site_id)
          content = "Unsubscribe from #{bindable.site_name}"
        else
          content = "Subscribe to #{bindable.site_name}"
        end

        {
          content: content,
          href: "/console/subscribe-toggle/#{bindable.site_id}"
        }
      else
        { view: ->(view) { view.remove } }
      end
    end
  end
end

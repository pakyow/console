Pakyow::App.routes :'console-platform' do
  include Pakyow::Console::SharedRoutes

  fn :platform_auth do
    auth = Rack::Auth::Basic::Request.new(req.env)

    if auth.provided? && auth.basic?
      creds = auth.credentials
      user = Pakyow::Console::Models::User.first(platform_token: creds[0], platform_token_secret: creds[1])
      handle 403 unless user
    else
      handle 403
    end
  end

  namespace :console, '/console', before: [:platform_auth] do
    restful :subscription, '/subscription' do
      # TODO: platform hits these routes when it confirms
      # that a subscription has been created or removed
      #
      # we problably want to build in some kind of confirmation
      # field so that we know for a fact that the subscrpition
      # record for the site is valid
      create do
        # expected params:
        #   project_id (project_id)

        # Pakyow::Console::Models::Subscription.create(project_id: params[:project_id])
      end

      remove do
        # expected params:
        #   subscription_id (oddly the project_id)

        # Pakyow::Console::Models::Subscription.where(project_id: params[:project_id]).delete
      end
    end

    restful :syndication, '/syndication' do
      create do
        # expected params:
        #   post.
        #     post_id
        #     site_id
        #     gravatar
        #     site_name
        #     site_url
        #     slug
        #     title
        #     content
        #     published_at

        unless post = Pakyow::Console::Models::SyndicatedPost.first(post_id: params[:post][:post_id])
          post = Pakyow::Console::Models::SyndicatedPost.new
        end

        post.set_all(params[:post])
        post.save

        ui.mutated(:"pw-post")
      end

      remove do
        if post = Pakyow::Console::Models::SyndicatedPost.first(post_id: params[:syndication_id])
          post.delete
          ui.mutated(:"pw-post")
        else
          handle 404
        end
      end
    end
  end
end

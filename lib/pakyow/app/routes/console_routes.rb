Pakyow::App.routes :console do
  include Pakyow::Console::SharedRoutes

  get 'robots' do
    handle 404 unless req.format == :txt
    send Pakyow::Console.robots.to_s
  end

  get 'sitemap' do
    handle 404 unless req.format == :xml
    send Pakyow::Console.sitemap.to_s
  end

  namespace :console, '/console' do
    get :default, '/' do
      redirect router.group(:console).path(:feed)
    end

    get :dashboard, '/dashboard' do
      redirect router.group(:console).path(:feed)
    end

    get :feed, '/feed', before: [:auth], after: [:setup] do
      if using_platform?
        presenter.path = 'console/dashboard/platform'

        view.scope(:"discover-tabs").with do |tabs_ctx|
          tabs_ctx.prop(:"tab-discover").attrs.class.ensure(:active)
          tabs_ctx.prop(:"tab-explore").attrs.class.deny(:active)
        end

        view.container(:default).scope(:"pw-post").mutate(:feed, with: data(:"pw-post").feed).subscribe

        drafts = Pakyow::Console::Models::Post.where(published: false).all

        view.partial(:sidebar).with do |sidebar_view|
          if drafts.empty?
            sidebar_view.scope(:"pw-post").remove
            sidebar_view.remove
          else
            sidebar_view.scope(:"pw-post").apply(drafts)
          end
        end
      end
    end

    get :explore, '/feed/discover', before: [:auth], after: [:setup] do
      if using_platform?
        presenter.path = 'console/dashboard/platform'
        view.title = "console/discover"

        view.scope(:"discover-tabs").with do |tabs_ctx|
          tabs_ctx.prop(:"tab-discover").attrs.class.deny(:active)
          tabs_ctx.prop(:"tab-explore").attrs.class.ensure(:active)
        end

        posts = platform_client.list_syndicated_posts
        view.container(:default).scope(:"pw-post").apply(posts)

        drafts = Pakyow::Console::Models::Post.where(published: false).all

        view.partial(:sidebar).with do |sidebar_view|
          if drafts.empty?
            sidebar_view.scope(:"pw-post").remove
            sidebar_view.remove
          else
            sidebar_view.scope(:"pw-post").apply(drafts)
          end
        end
      end
    end

    get :post, '/dashboard/post/:id', before: [:auth] do
      post = Pakyow::Console::Models::Post[params[:id]]

      unless post
        post = Pakyow::Console::Models::SyndicatedPost.first(post_id: params[:id])
      end

      unless post
        post = platform_client.fetch_syndicated_post(params[:id])
      end

      handle 404 unless post

      presenter.path = "console/dashboard/post"
      view.scope(:'pw-post').mutate(:show, with: post)
    end

    post "/subscribe-toggle/:project_id" do
      if subscription = Pakyow::Console::Models::Subscription.first(project_id: params[:project_id])
        platform_client.delete_subscription(params[:project_id])
        subscription.delete
      else
        platform_client.create_subscription(params[:project_id])
        Pakyow::Console::Models::Subscription.create(project_id: params[:project_id])
      end
    end
  end

  # loads configured routes
  # Pakyow::Console::RouteRegistry.config.each do |route|
  #   self.send(route[:method].downcase.to_sym, route[:name].to_sym, route[:path]) do
  #     begin
  #       presenter.path = route[:view_path]
  #     rescue MissingView
  #     end

  #     catch :halt do
  #       route[:functions].each do |function|
  #         invoke(function[:plugin], function[:function], function[:options])
  #       end
  #     end
  #   end
  # end
end

Pakyow::App.after :load do
  Pakyow::Router.instance.set :'console-catchall' do
    # This is the catch-all route for mapping to configured endpoints (plugins, pages, etc).
    # Registered in an after hook so it's at the end.
    #
    get /.*/ do
      Pakyow::Console.handle_slug(self)
    end
  end
end

Pakyow::App.after :reload do
  Pakyow::Router.instance.set :'console-catchall' do
    # This is the catch-all route for mapping to configured endpoints (plugins, pages, etc).
    # Registered in an after hook so it's at the end.
    #
    get /.*/ do
      Pakyow::Console.handle_slug(self)
    end
  end
end

require "uuid"

Pakyow::Console.slug_handler do
  path = String.normalize_path(req.path)

  if UUID.validate(path)
    @post = Pakyow::Console::Models::Post.first(id: path)
  else
    @post = Pakyow::Console::Models::Post.first(slug: path)
  end

  next if @post.nil? || !@post.published

  reroute router.group(:post).path(:show, post_id: @post.id)
end

Pakyow::App.after :load do
  Pakyow::Console::Models::Post.where(published: true).all do |post|
    Pakyow::Console.sitemap.url(
      location: File.join(Pakyow::Config.app.uri, post.slug),
      modified: post.updated_at.httpdate,
      frequency: 'weekly'
    )
  end
end

Pakyow::App.routes :'console-post' do
  include Pakyow::Console::SharedRoutes

  namespace :console, '/console' do
    restful :post, '/posts' do
      show after: [:prepare_project] do
        @post ||= Pakyow::Console::Models::Post[params[:post_id]]
        handle 404 if @post.nil? || !@post.published?

        presenter.path = "pw-post/show"
        template = presenter.store(:default).template(:default)
        partials = presenter.store(:console).partials('/pw-post/show').merge(presenter.store(:default).partials('/'))
        presenter.view = template.build(presenter.composer.page).includes(partials)

        view.title = "#{config.app.name} - #{@post.title}"
        view.scope(:'pw-post').mutate(:show, with: @post)
      end
    end
  end
end

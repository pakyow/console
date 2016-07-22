Pakyow::App.routes :'console-page' do
  include Pakyow::Console::SharedRoutes

  namespace :console, '/console' do
    restful :page, '/pages' do
      show after: [:prepare_project] do
        page = Pakyow::Console::Models::Page[params[:page_id]]
        handle 404 if page.nil? || !page.published?

        if page.fully_editable?
          template = presenter.store(:default).template(page.template.to_sym)
          presenter.view = template.build(page).includes(presenter.store(:default).partials('/'))
          presenter.view.title = String.presentable(page.name)
        else
          renderer_view = presenter.store(:console).view('/console/pages/template')
          presenter.view = presenter.store(:default).view(page.slug)
        end

        Pakyow::Console::Models::Page.editables_for_view(presenter.view).each do |editable|
          content = page.content_for(editable[:doc].get_attribute(:'data-editable'))
          parts = editable[:doc].editable_parts

          if parts.empty?
            rendered = renderer_view.scope(:content)[0].dup
            html = Pakyow::Console::ContentRenderer.render(content.content, view: rendered).to_html
            editable[:doc].clear
            editable[:doc].append(html)
          else
            editable[:doc].editable_parts.each_with_index do |part, i|
              rendered = renderer_view.scope(:content)[0].dup

              html = Pakyow::Console::ContentRenderer.render([content.content[i]], view: rendered, constraints: editable[:constraints]).to_html
              part[:doc].replace(html)
            end
          end

          # TODO: we need a way to configure the title template; e.g. !Magic: {page-title}
          presenter.view.title = String.presentable(page.name)
        end
      end
    end
  end
end

Pakyow::Console.slug_handler do
  page = Pakyow::Console.pages.find { |p| p.matches?(req.path) }
  next if page.nil? || !page.published

  reroute router.group(:page).path(:show, page_id: page.id)
end

Pakyow::App.after :load do
  Pakyow::Console.pages.select { |p| p.published }.each do |page|
    Pakyow::Console.sitemap.url(
      location: File.join(Pakyow::Config.app.uri, page.slug),
      modified: page.updated_at.httpdate,
      # FIXME: would be cool for platform to keep up with how often
      # content is updated so that this is dynamic
      frequency: 'weekly'
    )
  end
end

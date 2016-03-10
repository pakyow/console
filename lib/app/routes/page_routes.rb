Pakyow::App.routes :'console-page' do
  include Pakyow::Console::SharedRoutes

  namespace :console, '/console' do
    restful :page, '/pages' do
      show do
        page = Pakyow::Console::Models::Page[params[:page_id]]
        handle 404 if page.nil? || !page.published?

        if page.fully_editable?
          view = presenter.store(:console).view('/console/pages/template')
          Pakyow::Console::ContentRenderer.render(page, view: view.scope(:content)[0])

          vpage = Pakyow::Presenter::Page.new(page.name, view.scope(:content)[0].to_html, '/')
          presenter.compose_at('/', template: page.template.to_sym, page: vpage)

          # TODO: we need a way to configure the title template; e.g. !Magic: {page-title}
          presenter.view.title = page.name
        else
          renderer_view = presenter.store(:console).view('/console/pages/template')
          presenter.view = presenter.store(:default).view(page.slug)

          presenter.view.doc.editables.each do |editable|
            content = page.content_for(editable[:doc].get_attribute(:'data-editable'))
            parts = editable[:doc].editable_parts

            if parts.empty?
              rendered = renderer_view.scope(:content)[0].dup
              Pakyow::Console::ContentRenderer.render(content.content, view: rendered)
              editable[:doc].clear
              editable[:doc].append(rendered.to_html)
            else
              editable[:doc].editable_parts.each_with_index do |part, i|
                rendered = renderer_view.scope(:content)[0].dup

                constraints = part[:doc].get_attribute(:'data-constraints')

                if constraints
                  constraints = Hash.strhash(Hash[*constraints.split(';').map { |dim|
                    dim.split(':').map { |d| d.strip }
                  }.flatten])

                  part_type = part[:doc].get_attribute(:'data-editable-part').to_sym

                  constraints = {
                    part_type => {
                      default: constraints,
                      right: constraints,
                      left: constraints,
                    }
                  }
                end

                Pakyow::Console::ContentRenderer.render([content.content[i]], view: rendered, constraints: constraints)
                part[:doc].replace(rendered.to_html)
              end
            end
          end

          # TODO: we need a way to configure the title template; e.g. !Magic: {page-title}
          presenter.view.title = page.name
        end
      end
    end
  end
end

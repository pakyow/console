Pakyow::App.routes :'console-page' do
  include Pakyow::Console::SharedRoutes

  namespace :console, '/console' do
    restful :page, '/pages' do
      show do
        # TODO: the page needs to indicate whether it comes from editables, if
        # so we need to populate each editable rather than full rendering
        #
        page = Pakyow::Console::Page[params[:page_id]]
        handle 404 if page.nil? || !page.published?

        view = presenter.store(:console).view('/console/pages/template')
        Pakyow::Console::ContentRenderer.render(page, view: view.scope(:content)[0])

        vpage = Pakyow::Presenter::Models::Page.new(page.name, view.scope(:content)[0].to_html, '/')
        presenter.compose_at('/', template: page.template.to_sym, page: vpage)

        # TODO: we need a way to configure the title template; e.g. !Magic: {page-title}
        presenter.view.title = page.name
      end
    end
  end
end

module Pakyow
  module Console
    module Models
      class SyndicatedPost < Sequel::Model(Pakyow::Config.app.db[:'pw-syndicated_posts'].order(Sequel.desc(:published_at)))
        def html(console: true)
          renderer_view = Pakyow.app.presenter.store(:console).view('/console/pages/template')
          rendered = renderer_view.scope(:content)[0]
          Pakyow::Console::ContentRenderer.render(content, view: rendered, constraints: console ? Post::CONSTRAINTS :  Pakyow::Config.console.constraints, base_uri: image_url).to_html
        end

        def summary
          [content.first]
        end

        def summary_html(console: true)
          renderer_view = Pakyow.app.presenter.store(:console).view('/console/pages/template')
          rendered = renderer_view.scope(:content)[0]
          Pakyow::Console::ContentRenderer.render(summary, view: rendered, constraints: console ? Post::CONSTRAINTS :  Pakyow::Config.console.constraints, base_uri: image_url).to_html
        end

        def published?
          true
        end

        def permalink
          File.join(site_url, slug)
        end
        
        def image_url
          File.join(Pakyow::Config.console.platform_cdn, "projects", site_id)
        end
      end
    end
  end
end

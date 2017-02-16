module Pakyow
  module Console
    module Models
      class Post < Sequel::Model(Pakyow::Config.app.db[:'pw-posts'].order(Sequel.asc(:published), Sequel.desc(:published_at)))
        one_to_many :content, as: :owner
        add_association_dependencies content: :destroy
        many_to_one :user

        MONTHS = {
          '01' => 'January',
          '02' => 'February',
          '03' => 'March',
          '04' => 'April',
          '05' => 'May',
          '06' => 'June',
          '07' => 'July',
          '08' => 'August',
          '09' => 'September',
          '10' => 'October',
          '11' => 'November',
          '12' => 'December'
        }

        CONSTRAINTS = {
          image: {
            default: {
              width: 688,
              # height: 344,
              mode: :limit
            },

            right: {
              width: 334,
              # height: 167,
              mode: :limit
            },

            left: {
              width: 334,
              # height: 167,
              mode: :limit
            }
          }
        }
        
        def self.published
          where("published = ? and published_at <= ?", true, Time.now)
        end
        
        def self.unpublished
          where("published = ? or published_at > ?", false, Time.now)
        end

        def body
          content.first
        end

        def body=(content)
          @body = content
        end

        def before_save
          # TODO: on create we need to avoid slug collisions with other things in console
          @values[:slug] ||= String.slugify(title)
        end

        def after_save
          unless @body.nil?
            body = self.body || Pakyow::Console::Models::Content.new(owner: self)
            body.content = @body
            body.save
          end

          super
        end

        def published?
          published == true
        end

        def html(console: true)
          renderer_view = Pakyow.app.presenter.store(:console).view('/console/pages/template')
          rendered = renderer_view.scope(:content)[0]
          Pakyow::Console::ContentRenderer.render(body.content, view: rendered, constraints: console ? CONSTRAINTS :  Pakyow::Config.console.constraints).to_html
        end

        def summary
          [body.content.first]
        end

        def summary_html(console: true)
          renderer_view = Pakyow.app.presenter.store(:console).view('/console/pages/template')
          rendered = renderer_view.scope(:content)[0]
          Pakyow::Console::ContentRenderer.render(summary, view: rendered, constraints: console ? CONSTRAINTS :  Pakyow::Config.console.constraints).to_html
        end

        def permalink
          File.join(Pakyow::App.config.app.uri, slug)
        end

        def slug
          slug = @values[:slug]

          if slug.nil? || slug.empty?
            id
          else
            slug
          end
        end
      end
    end
  end
end

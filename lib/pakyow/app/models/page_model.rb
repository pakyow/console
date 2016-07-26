# TODO: this belongs in pakyow/support
class String
  def self.slugify(string)
    string.downcase.gsub('  ', ' ').gsub(' ', '-').gsub(/[^a-z0-9\/_-]/, '')
  end

  def self.presentable(string)
    string.gsub('-', ' ').gsub('_', ' ').split(' ').map { |part| part.capitalize }.join(' ')
  end
end

module Pakyow
  module Console
    module Models
      class Page < Sequel::Model(:'pw-pages')
        one_to_many :content, as: :owner
        many_to_one :parent, class: self
        alias_method :page, :parent

        add_association_dependencies content: :destroy

        set_allowed_columns :name, :parent, :template

        def self.editables_for_view(view)
          view.doc.editables.each_with_index do |editable, i|
            id = editable[:doc].get_attribute(:'data-editable')
            id = i if id.nil? || id.empty?
            editable[:id] = id
            editable[:constraints] = {}

            editable_constraints = editable[:doc].get_attribute(:'data-constraints')

            if editable_constraints
              editable_constraints = Hash.strhash(Hash[*editable_constraints.split(';').map { |dim|
                dim.split(':').map { |d| d.strip }
              }.flatten])

              # currently only image constraints are supported
              editable[:constraints][:image] = {
                default: editable_constraints,
                right: editable_constraints,
                left: editable_constraints,
              }
            end
          end
        end

        def validate
          validates_presence :name
          validates_presence :template# unless initial_value(:template).to_s == '__editable'

          # TODO: require unique slug (find a unique one automatically)
        end

        def after_create
          super

          find_and_create_editables

          return unless fully_editable?
          # TODO: this will go away once we can show containers right after selecting a template
          Pakyow.app.presenter.store(:default).template(template.to_sym).doc.containers.each do |container|
            container_name = container[0]

            content = {
              id: SecureRandom.uuid,
              scope: :content,
              type: :default,
              content: ''
            }

            add_content(content: [content], metadata: { id: container_name })
          end
        end

        def before_destroy
          Pakyow::Console::Models::InvalidPath.create(path: slug)
          super
        end

        def find_and_set_parent
          potential_parent_slug = slug.split('/')[0..-2].join('/')
          parent = self.class.first(slug: potential_parent_slug)
          return if parent.nil?
          self.parent = parent
        end

        def children
          self.class.where(parent_id: id, published: true).all
        end

        def name=(value)
          super
          @values[:slug] ||= String.normalize_path(String.slugify(value))
        end

        def relation_name
          name
        end

        def matches?(path)
          # TODO: this needs to be smart enough to handle parent
          String.normalize_path(path) == slug
        end

        def published?
          published == true
        end

        def editables
          if fully_editable?
            working_slug = self.slug
            partials = while true
              begin
                break Pakyow.app.presenter.store(:default).partials(working_slug)
              rescue Pakyow::Presenter::MissingView => e
                break {} if working_slug.empty?
                working_slug = working_slug.split('/')[0..-2].join('/')
              end
            end

            template = Pakyow.app.presenter.store(:default).template(self.template.to_sym)
            template.includes(partials)
            self.class.editables_for_view(template)
          else
            self.class.editables_for_view(Pakyow.app.presenter.store(:default).view(slug))
          end
        end

        def find_and_create_editables
          editables.each do |editable|
            next if content_for(editable[:id])
            parts = editable[:doc].editable_parts

            if parts.empty?
              content = {
                id: SecureRandom.uuid,
                scope: :content,
                type: :default,
                content: editable[:doc].html
              }

              add_content(content: [content], metadata: { id: editable[:id] })
            else
              content = []
              parts.each do |part|
                part_type = part[:doc].get_attribute(:'data-editable-part').to_sym
                part_alignment = part[:doc].get_attribute(:'data-align')
                part_hash = {
                  id: SecureRandom.uuid,
                  scope: :content,
                  type: part_type,
                  align: part_alignment,
                }

                if part_type == :default
                  part_hash[:content] = part[:doc].html
                elsif part_type == :image
                  images = []
                  oga_doc = Oga.parse_html(part[:doc].html)
                  oga_doc.css('img').each do |img_doc|
                    img_src = img_doc.get('src').gsub(/__[^\.]*/, '')
                    img_path = File.join(Pakyow::Config.app.root, 'app', 'assets', img_src)
                    next unless File.exists?(img_path)

                    img_file = File.open(img_path)
                    img_name = File.basename(img_path)
                    img_obj = Pakyow::Console::FileStore.instance.store(img_name, img_file, context: Pakyow::Console::FileStore::CONTEXT_MEDIA)

                    images << {
                      id: img_obj[:id],
                      thumb: "/console/files/#{img_obj[:id]}"
                    }
                  end

                  part_hash[:images] = images.to_json
                elsif part_type == :embed
                  oga_doc = Oga.parse_html(part[:doc].html)
                  embed_doc = oga_doc.css('iframe').first
                  part_hash[:code] = embed_doc.get('src')
                end

                content << part_hash
              end

              add_content(content: content, metadata: { id: editable[:id] })
            end
          end
        end

        def content_for(editable_id)
          content_dataset.where("metadata ->> 'id' = '#{editable_id}'").first
        end

        def content(editable_id = nil)
          return @values[:content] if editable_id.nil?

          content = content_for(editable_id)
          renderer_view = Pakyow.app.presenter.store(:console).view('/console/pages/template')
          rendered = renderer_view.scope(:content)[0]
          Pakyow::Console::ContentRenderer.render(content.content, view: rendered).to_html
        end

        def template
          template = @values[:template]

          if template == '__editable'
            composer = Pakyow.app.presenter.store(:default).composer(slug)
            composer.template.name
          else
            template
          end
        end

        def template=(value)
          return unless fully_editable?
          super
        end

        def parent=(parent)
          @values[:slug] = String.normalize_path(File.join(parent.slug, @values[:slug])) unless parent.nil? || @values[:slug].include?("#{parent.slug}/")
          super
        end

        def fully_editable?
          @values[:template] != '__editable'
        end
      end
    end
  end
end

# TODO: move to a more logical place
Pakyow::Console.after :page, :create do
  Pakyow::Console.invalidate_pages
end

Pakyow::Console.after :page, :update do
  Pakyow::Console.invalidate_pages
end

Pakyow::Console.after :page, :delete do
  Pakyow::Console.invalidate_pages
end

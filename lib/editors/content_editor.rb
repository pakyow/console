require 'uri'

Pakyow::Console.editor :content do |attribute, value|
  extras = attribute[:extras]
  partial = presenter.store(:console).partial('console/editors', :content).dup

  partial.includes({
    shared: presenter.store(:console).partial('console/editors', :shared).dup,
    actions: presenter.store(:console).partial('console/editors', :actions).dup,
    alignment: presenter.store(:console).partial('console/editors', :alignment).dup
  })

  view = Pakyow::Presenter::ViewContext.new(partial, self)

  if value
    value = value.to_json
    value = URI.escape(value)
    view.scope(:editor).attrs.value = value
  end

  view.scope(:constraints)[0].with do
    attrs.value = URI.escape(extras[:constraints].to_json)
    attrs[:'data-scope'] = nil
  end

  view.scope(:editor).attrs[:name] = "console-datum[#{attribute[:name]}]"
  view.scope(:editor).attrs[:'data-scope'] = nil

  if extras[:restricted]
    view.component(:'content-editor').attrs[:'data-config'] = 'restricted: true'
  end

  view.instance_variable_get(:@view)
end

module Pakyow::Console
  class ContentRenderer
    TYPES = [:default, :image, :embed, :break]

    # TODO: constraints should probably be passed in here
    # rather than being looked up as part of the attribute
    # basically decouple content rendering from datatypes
    def self.render(content, view: nil, attr: :content)
      templates = find_templates(view)
      datatype = DataTypeRegistry.for_model(content.class)
      attribute = datatype.attribute(attr)

      view.apply(content) do |view, datum|
        datum.send(attr).each do |piece|
          type = piece['type'].to_sym
          template = templates[type].dup
          renderer = ContentTypeRegistry.type(type)

          if renderer.nil?
            Pakyow.logger.debug "No content renderer for #{type}"
          else
            view.append(renderer.render(piece, template, attribute))
          end
        end
      end
    end

    def self.find_templates(view)
      templates = {}

      TYPES.each do |type|
        tv = view.scope("content-#{type}")[0]
        next if tv.nil?

        if tv.is_a?(Pakyow::Presenter::View)
          templates[type] = tv.dup
        else
          templates[type] = tv.subject.dup
        end

        tv.remove
      end

      templates
    end
  end
end

module Pakyow::Console::Content
  class Default
    def self.render(data, view, attribute)
      content = data['content']

      # NOTE: this is a workaround for trix, which uses <div> rather than <p>
      content.gsub!('<div>', '<p>')
      content.gsub!('</div>', '</p>')

      view.html = content
      view
    end
  end

  class Image
    def self.render(data, view, attribute)
      working = view

      if attribute[:extras] && attribute[:extras][:constraints]
        constraints = attribute[:extras][:constraints][:image]
      end

      alignment = data['align']
      alignment = 'default' if alignment.empty?

      JSON.parse(data['images']).each do |image|
        src = Pakyow::Router.instance.group(:file).path(:show, file_id: image['id'])
        file = Pakyow::Console::FileStore.instance.find(image['id'])

        width, height = file.values_at(:width, :height)

        if constraints
          constraints_for_alignment = constraints[alignment.to_sym]

          if constraints_for_alignment
            constraint_width, constraint_height = constraints_for_alignment.values_at(:width, :height)
            scale_factor = width / constraint_width.to_f

            width = constraint_width
            height = [height / scale_factor, constraint_height].min
          end
        end

        if width && height
          src << "?w=#{width}&h=#{height}"
        end

        if working.doc.tagname == 'img'
          working.attrs.src = src
        else
          working.attrs.style = {
            :'background-image' => "url(#{src})",
            :'background-size' => 'cover',

            width: "#{width}px",
            height: "#{height}px"
          }
        end

        working.attrs.class << "align-#{alignment}"

        working = view.dup
      end

      view
    end
  end

  class Break
    def self.render(data, view, attribute)
      view
    end
  end

  class Embed
    def self.render(data, view, attribute)
      embed_code = data['code']
      alignment = data['align']
      alignment = 'default' if alignment.empty?

      if embed_code.match('vimeo.com')
        id = embed_code.split('vimeo.com/')[1]
        html = '<div class="console-content-vimeo-wrapper"><iframe src="//player.vimeo.com/video/' + id + '" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe></div>'
        view.html = html
      end

      view.attrs.class << "align-#{alignment}"

      view
    end
  end
end

Pakyow::Console::ContentTypeRegistry.register(:default,
  Pakyow::Console::Content::Default
)

Pakyow::Console::ContentTypeRegistry.register(:image,
  Pakyow::Console::Content::Image
)

Pakyow::Console::ContentTypeRegistry.register(:break,
  Pakyow::Console::Content::Break
)

Pakyow::Console::ContentTypeRegistry.register(:embed,
  Pakyow::Console::Content::Embed
)

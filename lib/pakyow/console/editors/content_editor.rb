require 'uri'
require 'reverse_markdown'

module ReverseMarkdown
  module Converters
    class Pre < Base
      # TODO: consider PRing this
      def language_from_highlight_class(node)
        node['class'].to_s[/highlight ([a-zA-Z0-9]+)/, 1]
      end
    end
  end
end

Pakyow::Console.editor :content do |attribute, value|
  extras = attribute[:extras]
  partial = presenter.store(:console).partial('console/editors', :content).dup

  partial.includes({
    shared: presenter.store(:console).partial('console/editors', :shared).dup,
    actions: presenter.store(:console).partial('console/editors', :actions).dup,
    alignment: presenter.store(:console).partial('console/editors', :alignment).dup
  })

  view = Pakyow::Presenter::ViewContext.new(partial, self)
  view.scope(:content).prop(:content).use(current_console_user.preferred_editor.to_sym)

  if value
    content = value.is_a?(Sequel::Postgres::JSONArray) ? value : value.content

    if current_console_user.preferred_editor == 'markdown'
      # convert html back to markdown
      content = content.map { |content|
        if content['type'] == 'default'
          content['content'] = ReverseMarkdown.convert(content['content'], github_flavored: true)
        end

        content
      }
    end

    view.scope(:editor).attrs.value = URI.escape(content.to_json)
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

    def self.render(content, view: nil, constraints: Pakyow::Config.console.constraints)
      templates = find_templates(view)

      view.apply(content) do |_, piece|
        type = piece['type'].to_sym
        template = templates[type].dup
        renderer = ContentTypeRegistry.type(type)

        if renderer.nil?
          Pakyow.logger.debug "No content renderer for #{type}"
        else
          type_constraints = constraints.nil? ? nil : constraints[type]

          rendered = renderer.render(piece, template, type_constraints)
          if rendered.is_a?(Pakyow::Presenter::ViewCollection)
            rendered.each do |rendered_view|
              view.append(rendered_view)
            end
          else
            view.append(rendered)
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
    def self.render(data, view, constraints)
      view.html = data['content']
      view
    end
  end

  class Image
    def self.render(data, view, constraints)
      alignment = data['align']
      alignment = 'default' if alignment.nil? || alignment.empty?

      images = data['images'].is_a?(String) ? JSON.parse(data['images']) : data['images']
      collection = Pakyow::Presenter::ViewCollection.new

      images.each do |image|
        working = view.dup
        src = Pakyow::Router.instance.group(:file).path(:show, file_id: image['id'])
        file = Pakyow::Console::FileStore.instance.find(image['id'])

        width, height = file.values_at(:width, :height)

        if constraints
          constraints_for_alignment = constraints[alignment.to_sym]

          constraint_mode = Pakyow::Console::FileStore::DEFAULT_MODE
          if constraints_for_alignment
            constraint_width, constraint_height, constraint_mode = constraints_for_alignment.values_at(:width, :height, :mode)
            scale_factor = width.to_i / constraint_width.to_f

            width = constraint_width.to_i
            height = [height.to_i / scale_factor, constraint_height.to_i].reject { |n| n == 0 }.min
          end
        end

        if width && height
          src << "?w=#{width}&h=#{height}&m=#{constraint_mode}"
        end

        if working.doc.tagname == 'img'
          working.attrs.src = src
        else
          style = {
            :'background-image' => "url(#{src})",
            :'background-repeat' => 'no-repeat',
            :'background-position' => 'center',
            width: "#{width}px",
            height: "#{height}px"
          }

          if constraint_mode == :fill
            style[:'background-size'] = 'cover'
          end

          working.attrs.style = style
        end

        working.attrs.class << "align-#{alignment}"
        collection << working
      end

      collection
    end
  end

  class Break
    def self.render(data, view, constraints)
      view
    end
  end

  class Embed
    def self.render(data, view, constraints)
      embed_code = data['code']
      alignment = data['align']
      alignment = 'default' if alignment.nil? || alignment.empty?

      if embed_code.match('player.vimeo.com/video/')
        id = embed_code.split('player.vimeo.com/video/')[1]
        html = '<div class="console-content-vimeo-wrapper"><iframe src="//player.vimeo.com/video/' + id + '" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe></div>'
        view.html = html
      elsif embed_code.match('vimeo.com/')
        id = embed_code.split('vimeo.com/')[1]
        html = '<div class="console-content-vimeo-wrapper"><iframe src="//player.vimeo.com/video/' + id + '" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe></div>'
        view.html = html
      elsif embed_code.match('youtube.com/watch?v=')
        id = embed_code.split('youtube.com/watch?v=')[1]
        html = '<div class="console-content-youtube-wrapper"><iframe src="//www.youtube.com/embed/' + id + '" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe></div>'
        view.html = html
      elsif embed_code.match('youtu.be/')
        id = embed_code.split('youtu.be/')[1]
        html = '<div class="console-content-youtube-wrapper"><iframe src="//www.youtube.com/embed/' + id + '" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe></div>'
        view.html = html
      elsif embed_code.match('youtube.com/embed/')
        id = embed_code.split('youtube.com/embed/')[1]
        html = '<div class="console-content-youtube-wrapper"><iframe src="//www.youtube.com/embed/' + id + '" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe></div>'
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

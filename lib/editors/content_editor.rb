require 'uri'

Pakyow::Console.editor :content do |_, value|
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

  view.scope(:editor).attrs[:'data-scope'] = nil
  view.instance_variable_get(:@view)
end

module Pakyow::Console
  class ContentRenderer
    TYPES = [:default, :image, :embed, :break]

    def self.render(content, view)
      view.apply(content) do |view, datum|
        templates = find_templates(view)

        datum[:content].each do |piece|
          type = piece['type'].to_sym
          template = templates[type]
          renderer = ContentTypeRegistry.type(type)

          if renderer.nil?
            Pakyow.logger.debug "No content renderer for #{type}"
          else
            view.append(renderer.render(piece, template))
          end
        end
      end
    end

    def self.find_templates(view)
      templates = {}

      TYPES.each do |type|
        tv = view.scope("content-#{type}")[0]
        next if tv.nil?

        templates[type] = tv.dup
        tv.remove
      end

      templates
    end
  end
end

module Pakyow::Console::Content
  class Default
    def self.render(data, view)
      view.text = data['content']
      view
    end
  end

  class Image
    def self.render(data, view)
      view
    end
  end

  class Break
    def self.render(data, view)
      view
    end
  end

  class Embed
    def self.render(data, view)
      view
    end
  end
end

Pakyow::Console::ContentTypeRegistry.register(:default, Pakyow::Console::Content::Default)

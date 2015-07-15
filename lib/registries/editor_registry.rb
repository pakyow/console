module Pakyow::Console::EditorRegistry
  def self.register(*types, &block)
    types.each do |type|
      editors[type] = block
    end
  end

  def self.editor_for_attribute(attribute, datum)
    view = editors.fetch(attribute[:type]).call(attribute[:extras], datum[attribute[:name]])
    view.scope(:editor).attrs.class.ensure("editor-#{attribute[:type]}")
    view.scope(:editor).attrs[:'data-prop'] = attribute[:name].to_s
    view.scope(:editor).attrs[:'data-scope'] = nil
    view
  rescue KeyError
    'Unknown Editor'
  end

  private

  def self.editors
    @editors ||= {}
  end
end

module Pakyow::Console::EditorRegistry
  def self.register(*types, &block)
    types.each do |type|
      editors[type] = block
    end
  end

  def self.editor_for_attribute(attribute, datum, type, context)
    value = if attribute[:extras].key?(:value)
      attribute[:extras][:value].call(datum)
    else
      datum.is_a?(Hash) ? datum[attribute[:name]] : datum.send(attribute[:name])
    end

    view = context.instance_exec(attribute, value, attribute, datum, type, &editors.fetch(attribute[:type]))
    # In a custom editor that either sets everything literally or maybe returns a view
    #   with multiple form elements, it might not have an 'editor' scope.
    if view.scope(:editor)
      view.scope(:editor).attrs.class.ensure("editor-#{attribute[:type]}")
      view.scope(:editor).attrs[:'data-prop'] = attribute[:name].to_s
      view.scope(:editor).attrs[:'data-scope'] = nil
    end
    view
  rescue KeyError
    'Unknown Editor'
  end

  private

  def self.editors
    @editors ||= {}
  end
end

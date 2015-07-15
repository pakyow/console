module Pakyow::Helpers
  def setup_datum_form
    view.partial(:form).scope(:'console-datum').with do |view|
      view.scope(:'console-data-field').apply(@type.attributes) do |view, attribute|
        editor = Pakyow::Console::EditorRegistry.editor_for_attribute(attribute, @datum || {})

        view.prop(:editor)[0].replace(editor)
        view.attrs[:'data-scope'] = nil
        view.attrs[:'data-prop'] = nil
      end

      view.bind(Pakyow::Console::DatumFormatterRegistry.format(@datum || {}, as: @type))
    end

    handle_errors(view.partial(:errors), object_type: :datum)
  end
end

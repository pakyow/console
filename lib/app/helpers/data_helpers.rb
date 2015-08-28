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

    view.partial(:actions).with do |view|
      if @datum && @datum.id
        actions = @type.actions.select { |action|
          action[:display].nil? || action[:display].call(@datum)
        }

        view.scope(:'console-datum-action').apply(actions) do |view, action|
          path = "/console/data/#{params[:data_id]}/datum/#{@datum.id}/#{action[:name]}"

          view.prop(:action).with do |view|
            if action[:name] == :remove
              view.attrs.action = router.group(:datum).path(:remove, data_id: params[:data_id], datum_id: params[:datum_id])
            else
              view.attrs.action = path
            end
          end

          view.prop(:method).with do |view|
            if action[:name] == :remove
              view.attrs.value = 'DELETE'
            else
              view.remove
            end
          end

          view.prop(:label).text = action[:label]
        end
      else
        view.remove
      end
    end
  end
end

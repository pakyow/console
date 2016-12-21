module Pakyow::Helpers
  def current_plugin
    @mounted_plugin
  end

  def setup_datum_form
    view.partial(:form).scope(:'console-datum').with do |view|
      attributes = @type.attributes(@datum).select { |attribute|
        !attribute[:extras].key?(:display) || attribute[:extras][:display].call(@datum)
      }

      view.scope(:'console-data-field').apply(attributes) do |view, attribute|
        editor = Pakyow::Console::EditorRegistry.editor_for_attribute(attribute, @datum || {}, @type, self)
        view.prop(:editor)[0].replace(editor)
        view.attrs[:'data-scope'] = nil
        view.attrs[:'data-prop'] = nil
      end

      view.bind(Pakyow::Console::DatumFormatterRegistry.format(@datum || @type.model_object.new, as: @type))
    end

    object_id = @datum ? @datum.id : nil
    handle_errors(view.partial(:errors), object_type: @type.name, object_id: object_id)
  end
  
  def setup_datum_actions
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

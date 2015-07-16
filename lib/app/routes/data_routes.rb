Pakyow::App.routes :'console-data' do
  include Pakyow::Console::SharedRoutes

  namespace :console, '/console' do
    restful :data, '/data', before: [:auth], after: [:setup, :notify] do
      show do
        @current_type = params[:data_id]

        type = Pakyow::Console::DataTypeRegistry.type(@current_type)
        listables = type.attributes.reject { |a|
          Pakyow::Console::DataTypeRegistry::UNLISTABLE_TYPES.include?(a[:type])
        }

        view.scope(:'console-data-field').apply(listables)

        view.container(:default).scope(:'console-data-type').bind(type)

        data = type.model_object.all
        view.partial(:table).scope(:'console-datum').apply(data) do |view, datum|
          view.scope(:'console-data-value').repeat(listables) do |view, type|
            value = datum[type[:name]]

            if value.nil? || (value.is_a?(String) && value.empty?)
              text = '-'
            else
              text = value.to_s
            end

            view.text = text
          end
        end
      end

      restful :datum, '/datum' do
        new do
          #FIXME why do I have to do this on a reroute?
          presenter.path = 'console/data/datum/new'

          @type = Pakyow::Console::DataTypeRegistry.type(params[:data_id])
          view.container(:default).scope(:'console-data-type').bind(@type)

          setup_datum_form
        end

        create do
          @type = Pakyow::Console::DataTypeRegistry.type(params[:data_id])
          @datum = @type.model_object.new(Pakyow::Console::DatumProcessorRegistry.process(params[:'console-datum'], as: @type))

          if @datum.valid?
            #TODO this is where we'll want to let registered processors process
            # the incoming data (especially important for media + file types)

            @datum.save
            notify("#{@type.nice_name.downcase} created", :success)
            redirect router.group(:datum).path(:edit, data_id: params[:data_id], datum_id: @datum.id)
          else
            notify("failed to create a #{@type.nice_name.downcase}", :fail)
            res.status = 400

            @errors = @datum.errors.full_messages
            reroute router.group(:datum).path(:new, data_id: params[:data_id]), :get
          end
        end

        edit do
          #FIXME why do I have to do this on a reroute?
          presenter.path = 'console/data/datum/edit'

          @type = Pakyow::Console::DataTypeRegistry.type(params[:data_id])
          view.container(:default).scope(:'console-data-type').bind(@type)

          @datum ||= @type.model_object[params[:datum_id]]
          setup_datum_form
        end

        update do
          @type = Pakyow::Console::DataTypeRegistry.type(params[:data_id])

          current = @type.model_object[params[:datum_id]]
          @datum = current.set(Pakyow::Console::DatumProcessorRegistry.process(params[:'console-datum'], current, as: @type))

          if @datum.valid?
            #TODO this is where we'll want to let registered processors process
            # the incoming data (especially important for media + file types)

            @datum.save
            notify("#{@type.nice_name.downcase} updated", :success)
            redirect router.group(:datum).path(:edit, data_id: params[:data_id], datum_id: @datum.id)
          else
            notify("failed to create a #{@type.nice_name.downcase}", :fail)
            res.status = 400

            @errors = @datum.errors.full_messages
            reroute router.group(:datum).path(:edit, data_id: params[:data_id], datum_id: params[:datum_id]), :get
          end
        end

        remove do
          type = Pakyow::Console::DataTypeRegistry.type(params[:data_id])
          type.model_object[params[:datum_id]].delete

          redirect router.group(:data).path(:show, data_id: params[:data_id])
        end
      end
    end
  end
end

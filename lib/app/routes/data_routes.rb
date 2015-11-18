Pakyow::App.routes :'console-data' do
  include Pakyow::Console::SharedRoutes

  namespace :console, '/console' do
    restful :data, '/data', before: [:auth], after: [:setup, :notify] do
      show do
        begin # try to use a custom view and fallback on the schema builder
          presenter.path = req.path
          @custom = true
        rescue Pakyow::Presenter::MissingView
        end

        @current_type = params[:data_id]
        type = Pakyow::Console::DataTypeRegistry.type(@current_type)
        data = type.model_object.all

        # setup the page header
        view.container(:default).scope(:'console-data-type').bind(type)

        if @custom
          view.scope(:"pw-#{@current_type}").apply(data)
        else
          # find the fields we want to display
          listables = type.attributes.reject { |a|
            Pakyow::Console::DataTypeRegistry::UNLISTABLE_TYPES.include?(a[:type])
          }

          view.scope(:'console-data-field').apply(listables)

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

          @datum = @type.model_object.new
          @datum.set_all(Pakyow::Console::DatumProcessorRegistry.process(params[:'console-datum'], as: @type))

          Pakyow::Console::ServiceHookRegistry.call(:before, :create, @type.name, @datum, self)

          if @datum.valid?
            #TODO this is where we'll want to let registered processors process
            # the incoming data (especially important for media + file types)

            @datum.save
            ui.mutated(:datum)
            Pakyow::Console::ServiceHookRegistry.call(:after, :create, @type.name, @datum, self)
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
          @datum = current.set_all(Pakyow::Console::DatumProcessorRegistry.process(params[:'console-datum'], current, as: @type))
          Pakyow::Console::ServiceHookRegistry.call(:before, :update, @type.name, @datum, self)

          if @datum.valid?
            #TODO this is where we'll want to let registered processors process
            # the incoming data (especially important for media + file types)

            @datum.save
            ui.mutated(:datum)
            Pakyow::Console::ServiceHookRegistry.call(:after, :update, @type.name, @datum, self)
            notify("#{@type.nice_name.downcase} updated", :success)
            redirect router.group(:datum).path(:edit, data_id: params[:data_id], datum_id: @datum.id)
          else
            notify("failed to update a #{@type.nice_name.downcase}", :fail)
            res.status = 400

            @errors = @datum.errors.full_messages
            reroute router.group(:datum).path(:edit, data_id: params[:data_id], datum_id: params[:datum_id]), :get
          end
        end

        remove do
          type = Pakyow::Console::DataTypeRegistry.type(params[:data_id])
          datum = type.model_object[params[:datum_id]]

          Pakyow::Console::ServiceHookRegistry.call(:before, :delete, type.name, datum, self)
          datum.destroy
          Pakyow::Console::ServiceHookRegistry.call(:after, :delete, type.name, datum, self)

          notify("#{type.nice_name.downcase} deleted", :success)
          redirect router.group(:data).path(:show, data_id: params[:data_id])
        end

        #FIXME why doesn't `member` or `collection` work on nested restful resources?
        # it may also be incorrectly triggering an incorrect message when an error
        # occurs during dynamic route creation :/
        Pakyow::Console::DataTypeRegistry.types.each do |type|
          type.actions.each do |action|
            url = ":datum_id/#{action[:name]}"
            method = action[:name] == :remove ? :delete : :post

            send(method, url) do
              type = Pakyow::Console::DataTypeRegistry.type(params[:data_id])
              datum = type.model_object[params[:datum_id]]
              instance_exec(datum, &action[:logic])
              notify(action[:notification], :success)
              redirect router.group(:datum).path(:edit, data_id: params[:data_id], datum_id: params[:datum_id])
            end
          end
        end
      end
    end
  end
end

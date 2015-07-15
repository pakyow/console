Pakyow::App.routes :'console-user' do
  include Pakyow::Console::SharedRoutes

  namespace :console, '/console' do
    restful :user, '/users', before: [:auth], after: [:setup, :notify] do
      list do
        # the mutation (list) is tied to the relation (all) so we know exactly how to perform updates in the future
        #TODO keep track of the mutation AND the relation when subscribing
        # subscriptions should be tracked globaly in redis rather than by each app instance
        # when a mutation occurs it should be pushed to a redis queue for the next available app instance to process
        # the app instance runs the mutation again (which consists of the mutation itself and the data source)
        # when the mutation is finished it is broadcast via the same mechanisms we have currently so each app instance updates its views
        # for now, just track it on a single app instance; we can deal with it from there
        view.container(:default).scope(:user).mutate(:list, with: data(:user).all).subscribe

        #TODO qualifications should be added to this:
        # mutate(:list, with: :all, qualify: { user_id: current_user.id }).subscribe
        # the above would tell the source to show the list for a single user; the subscription would not be qualified
        # mutate(:list, with: :all).qualify({ user_id: current_user.id }).subscribe
        # the above would qualify the mutation + the subscription; for cases where the user's list should only be available to the user
        # mutate(:list, with: :all).subscribe(user_id: current_user.id)
      end

      new do
        view.title = "users/new"

        view.partial(:form).scope(:user).with do |view|
          view.bind(@user || {})
        end

        handle_errors(view.partial(:errors), object_type: :user)
      end

      create do
        @user = Pakyow::Console::User.new(params[:user])
        @user.role = 'admin'

        if @user.valid?
          @user.save

          notify('user created', :success, redirect: router.group(:user).path(:list))
        else
          notify('failed to create a user', :fail)
          res.status = 400

          @errors = @user.errors.full_messages
          reroute router.group(:user).path(:new), :get
        end
      end

      edit do
        handle 404 unless @user ||= Pakyow::Console::User[params[:user_id]]

        presenter.path = 'console/users/edit'

        view.title = "users/#{@user.username}"
        view.container(:default).scope(:user).bind(@user)
        view.partial(:form).scope(:user).bind(@user)

        # setup delete user
        #TODO would be nice to have objects on the backend that define logic to be executed for some partial (after the route)
        view.partial(:delete).scope(:user).with do |view|
          #TODO need some sort of `setup_form` helper instead of binding objects
          view.attrs.action = router.group(:user).path(:remove, user_id: params[:user_id])
        end

        handle_errors(view.partial(:errors), object_type: :user)
      end

      update do
        handle 404 unless @user = Pakyow::Console::User[params[:user_id]]
        @user.set(params[:user])

        if @user.valid?
          @user.save

          notify('user updated', :success, redirect: router.group(:user).path(:list))
        else
          notify('failed to update the user', :fail)
          res.status = 400

          @errors = @user.errors.full_messages
          reroute router.group(:user).path(:edit, user_id: params[:user_id]), :get
        end
      end

      remove do
        handle 404 unless @user = Pakyow::Console::User[params[:user_id]]
        @user.delete

        notify('user deleted', :success, redirect: router.group(:user).path(:list))
      end
    end
  end
end

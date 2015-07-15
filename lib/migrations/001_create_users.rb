require_relative '../pakyow-console'
#TODO need a way to run these migrations in a user's app
# possibly by creating a stub in their migration dir with
# the appropriate order, then requiring this migration
Sequel.migration do
  up do
    create_table :'pw-users' do
      primary_key   :id
      String        :email
      String        :username
      String        :name
      String        :role
      TrueClass     :active, default: true
      String        :crypted_password
      Time          :created_at
      Time          :updated_at
    end
  end

  down do
    drop_table :'pw-users'
  end
end

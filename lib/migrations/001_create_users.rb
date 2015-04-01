require_relative '../pakyow-console'

Sequel.migration do
  up do
    create_table :users do
      primary_key   :id
      String        :email
      String        :name
      String        :role
      TrueClass     :active, default: true
      String        :crypted_password
      String        :salt
      Time          :created_at
      Time          :updated_at
    end
  end

  down do
    drop_table :users
  end
end

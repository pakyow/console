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

      index [:email, :username, :role, :active]
    end
  end

  down do
    drop_table :'pw-users'
  end
end

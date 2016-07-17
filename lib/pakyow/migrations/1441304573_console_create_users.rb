Sequel.migration do
  up do
    create_table :'pw-users' do
      column        :id, :uuid, default: Sequel.function(:uuid_generate_v4), primary_key: true
      String        :email
      String        :username
      String        :name
      String        :role
      TrueClass     :active, default: true
      String        :crypted_password
      String        :timezone
      column        :platform_user_id
      column        :platform_token, :uuid
      column        :platform_token_secret
      Time          :created_at
      Time          :updated_at

      index [:email, :username, :role, :active]
    end
  end

  down do
    drop_table :'pw-users'
  end
end

Sequel.migration do
  up do
    create_table :'pw-mounted-plugins' do
      column        :id, :uuid, default: Sequel.function(:uuid_generate_v4), primary_key: true
      String        :name
      String        :slug
      json          :config
      FalseClass    :active
      Time          :activated_at
      Time          :created_at
      Time          :updated_at

      index [:name, :slug, :active]
    end
  end

  down do
    drop_table :'pw-mounted-plugins'
  end
end

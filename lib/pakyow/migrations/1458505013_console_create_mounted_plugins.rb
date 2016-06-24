Sequel.migration do
  up do
    create_table :'pw-mounted-plugins' do
      primary_key   :id
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

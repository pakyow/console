Sequel.migration do
  up do
    create_table :'pw-navigations' do
      column        :id, :uuid, default: Sequel.function(:uuid_generate_v4), primary_key: true
      String        :name
      Time          :created_at
      Time          :updated_at

      index [:name]
    end
  end

  down do
    drop_table :'pw-navigations'
  end
end

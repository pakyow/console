Sequel.migration do
  up do
    create_table :'pw-invalid-paths' do
      column        :id, :uuid, default: Sequel.function(:uuid_generate_v4), primary_key: true
      String        :path
      Time          :created_at
      Time          :updated_at

      index [:path]
    end
  end

  down do
    drop_table :'pw-invalid-paths'
  end
end

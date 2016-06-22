Sequel.migration do
  up do
    create_table :'pw-files' do
      column        :id, :uuid, default: Sequel.function(:uuid_generate_v4), primary_key: true
      File          :data
      json          :metadata
      Time          :created_at
      Time          :updated_at
    end
  end

  down do
    drop_table :'pw-files'
  end
end

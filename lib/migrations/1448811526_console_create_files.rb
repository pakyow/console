Sequel.migration do
  up do
    create_table :'pw-files' do
      primary_key   :id
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

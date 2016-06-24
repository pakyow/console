Sequel.migration do
  up do
    create_table :'pw-invalid-paths' do
      primary_key   :id
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

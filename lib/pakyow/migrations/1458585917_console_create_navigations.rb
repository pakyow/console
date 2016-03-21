Sequel.migration do
  up do
    create_table :'pw-navigations' do
      primary_key   :id
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

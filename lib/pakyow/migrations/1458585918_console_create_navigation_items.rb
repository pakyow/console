Sequel.migration do
  up do
    create_table :'pw-navigation-items' do
      primary_key   :id
      foreign_key   :navigation_id, :'pw-navigations'
      Integer       :order
      String        :group

      Integer       :endpoint_id
      String        :endpoint_type

      String        :name
      String        :slug
      FalseClass    :active
      Time          :activated_at

      Time          :created_at
      Time          :updated_at

      index [:endpoint_id, :endpoint_type, :order, :group]
    end
  end

  down do
    drop_table :'pw-navigation-items'
  end
end

Sequel.migration do
  up do
    create_table :'pw-navigation-items' do
      column        :id, :uuid, default: Sequel.function(:uuid_generate_v4), primary_key: true
      foreign_key   :navigation_id, :'pw-navigations', type: :uuid
      Integer       :order
      String        :group

      column        :endpoint_id, :uuid
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

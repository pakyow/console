Sequel.migration do
  up do
    create_table :'pw-subscriptions' do
      column        :id, :uuid, default: Sequel.function(:uuid_generate_v4), primary_key: true
      column        :project_id, :uuid
      Time          :created_at
      Time          :updated_at
    end
  end

  down do
    drop_table :'pw-subscriptions'
  end
end

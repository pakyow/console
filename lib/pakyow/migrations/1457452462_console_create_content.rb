Sequel.migration do
  up do
    create_table :'pw-content' do
      column        :id, :uuid, default: Sequel.function(:uuid_generate_v4), primary_key: true
      column        :owner_id, :uuid
      String        :owner_type
      json          :content
      json          :metadata
      FalseClass    :published
      Time          :published_at
      Time          :created_at
      Time          :updated_at

      index [:owner_id, :owner_type, :published]
    end
  end

  down do
    drop_table :'pw-content'
  end
end

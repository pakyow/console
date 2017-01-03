Sequel.migration do
  up do
    create_table :'pw-collections' do
      column        :id, :uuid, default: Sequel.function(:uuid_generate_v4), primary_key: true
      String        :slug
      String        :name
      FalseClass    :published
      Time          :published_at
      Time          :created_at
      Time          :updated_at

      index [:slug, :published]
    end
  end

  down do
    drop_table :'pw-collections'
  end
end

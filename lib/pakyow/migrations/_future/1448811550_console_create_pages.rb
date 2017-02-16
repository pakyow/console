Sequel.migration do
  up do
    create_table :'pw-pages' do
      column        :id, :uuid, default: Sequel.function(:uuid_generate_v4), primary_key: true
      foreign_key   :parent_id, :'pw-pages', type: :uuid
      String        :slug
      String        :name
      String        :template
      json          :metadata
      FalseClass    :published
      Time          :published_at
      Time          :created_at
      Time          :updated_at

      index [:parent_id, :slug, :template, :published]
    end
  end

  down do
    drop_table :'pw-pages'
  end
end

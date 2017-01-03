Sequel.migration do
  up do
    create_table :'pw-posts' do
      column :id, :uuid, default: Sequel.function(:uuid_generate_v4), primary_key: true
      foreign_key   :user_id, :'pw-users', type: :uuid
      String        :title
      String        :slug
      json          :tags
      json          :metadata
      json          :config
      FalseClass    :published, default: false
      Time          :published_at
      Time          :created_at
      Time          :updated_at
    end
  end

  down do
    drop_table :'pw-posts'
  end
end

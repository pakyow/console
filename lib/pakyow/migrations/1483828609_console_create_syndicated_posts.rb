Sequel.migration do
  up do
    create_table :'pw-syndicated_posts' do
      column        :id, :uuid, default: Sequel.function(:uuid_generate_v4), primary_key: true
      column        :post_id, :uuid
      column        :site_id, :uuid
      String        :gravatar
      String        :site_name
      String        :site_url
      String        :slug
      String        :title
      json          :content
      Time          :published_at
      Time          :created_at
      Time          :updated_at
    end
  end

  down do
    drop_table :'pw-syndicated_posts'
  end
end

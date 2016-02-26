Sequel.migration do
  up do
    create_table :'pw-pages' do
      primary_key   :id
      Integer       :parent_id
      String        :slug
      String        :name
      String        :template
      json          :content
      json          :metadata
      FalseClass    :published
      Time          :published_at
      Time          :created_at
      Time          :updated_at
    end
  end

  down do
    drop_table :'pw-pages'
  end
end

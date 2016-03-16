Sequel.migration do
  up do
    create_table :'pw-content' do
      primary_key   :id
      Integer       :version_id
      Integer       :owner_id
      String        :owner_type
      json          :content
      json          :metadata
      FalseClass    :published
      Time          :published_at
      Time          :created_at
      Time          :updated_at

      index [:owner_id, :owner_type]
    end
  end

  down do
    drop_table :'pw-content'
  end
end

Sequel.migration do
  up do
    alter_table :'pw-users' do
      add_column :preferred_editor, String, default: 'wysiwyg'
    end
  end

  down do
    alter_table :'pw-users' do
      drop_column :preferred_editor
    end
  end
end

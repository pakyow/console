Sequel.migration do
  up do
    begin
      run 'CREATE EXTENSION "uuid-ossp"'
    rescue Sequel::DatabaseError
      raise Sequel::Rollback
    end
  end
end

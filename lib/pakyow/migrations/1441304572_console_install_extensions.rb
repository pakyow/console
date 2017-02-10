Sequel.migration do
  up do
    run 'CREATE EXTENSION "uuid-ossp"'
  end
end

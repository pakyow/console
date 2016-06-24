require 'yaml'

module Pakyow::Console::RouteRegistry
  def self.all
    #TODO show overrides
    config.concat(app_routes).sort { |a,b| a[:path] <=> b[:path] }
  end

  def self.save(route)
    new_config = config

    if existing_route = new_config.find { |eroute| eroute[:id] == route[:id] }
      new_config.delete(existing_route)
    end

    new_config << route.to_h
    write(new_config)
  end

  def self.find(id)
    Pakyow::Console::Route.new(config.find { |route|
      route[:id] == id
    })
  end

  private

  def self.app_routes
    set = Pakyow::Router.instance.sets[:main]
    set.routes.flat_map { |route_data|
      method, routes = route_data
      routes.map { |route|
        group = nil
        set.lookup[:grouped].each_pair {|name,routes|
          if routes.values.include?(route)
            group = name
            break
          end
        }

        name = route[2]
        name = "#{group}[#{name}]" if group

        {
          type: :pakyow,
          method: method,
          path: File.join('/', route[4]),
          name: name
        }
      }
    }
  end

  def self.config
    unless File.exists?(config_path)
      write([])
    end

    YAML.load_file(config_path).map { |config|
      Hash.strhash(config)
    }
  end

  def self.config_path
    File.join(Pakyow::App.config.app.root, 'routes.yaml')
  end

  def self.write(config)
    File.open(config_path, 'w') { |f|
      f.write(config.to_yaml)
    }
  end
end

require 'yaml'

module Pakyow::Console::Routes
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

class Pakyow::Console::Route
  attr_reader :errors, :id, :name, :method, :path, :view_path

  def initialize(values)
    @id, @last_modified, @type, @name, @method, @path, @view_path, @author, @functions = values.values_at(:id, :last_modified, :type, :name, :method, :path, :view_path, :author, :functions)
  end

  def [](var)
    instance_variable_get(:"@#{var}")
  end

  def valid?
    @errors = []

    %w[name method path].each do |var|
      value = instance_variable_get(:"@#{var}")
      if value.nil? || value.empty?
        @errors << "#{var} is required"
      end
    end

    @errors.count == 0
  end

  def update(values)
    @name, @method, @path, @view_path = values.values_at(:name, :method, :path, :view_path)
  end

  def save
    return unless valid?
    @id ||= SecureRandom.hex(16)
    Pakyow::Console::Routes.save(self)
  end

  def to_h
    {
      id: @id,
      name: @name,
      method: @method.upcase,
      path: "/#{String.normalize_path(@path)}",
      view_path: String.normalize_path(view_path),
      type: :console,
      last_modified: Time.now,
      author: {
        name: @author[:name],
        gravatar: @author[:gravatar] || @author.gravatar_hash
      },
      functions: @functions
    }
  end

  def view_path
    return @path if @view_path.nil? || @view_path.empty?
    @view_path
  end
end

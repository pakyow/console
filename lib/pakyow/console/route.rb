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
    Pakyow::Console::RouteRegistry.save(self)
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
        gravatar: @author[:gravatar] || Digest::MD5.hexdigest(@author.email)
      },
      functions: @functions
    }
  end

  def view_path
    return @path if @view_path.nil? || @view_path.empty?
    @view_path
  end
end

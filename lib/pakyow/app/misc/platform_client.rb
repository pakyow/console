require 'net/http/post/multipart'

class PlatformClient
  class << self
    def auth(email, password)
      response = HTTParty.post(File.join(Pakyow::Config.console.platform_url, 'auth/token'), body: {
        login: email,
        password: password,
      })

      if response.code == 200
        Hash.strhash(JSON.parse(response.body))
      end
    end
  end

  def initialize(email, token, info)
    @email = email
    @token = token
    @info  = info
  end

  def valid?
    response = HTTParty.get(File.join(Pakyow::Config.console.platform_url, 'api/projects'), basic_auth: {
      username: @email,
      password: @token,
    })

    response.code == 200
  end

  def socket
    if app = @info[:app]
      response = HTTParty.post(File.join(Pakyow::Config.console.platform_url, 'api/projects', app[:id].to_s, 'socket'), basic_auth: {
        username: @email,
        password: @token,
      })

      Hash.strhash(JSON.parse(response.body))
    else
      {}
    end
  end

  # TODO: refactor to `projects`
  def apps
    response = HTTParty.get(File.join(Pakyow::Config.console.platform_url, 'api/projects'), basic_auth: {
      username: @email,
      password: @token,
    })

    JSON.parse(response.body).map { |app|
      # TODO: this blows up when we get a non-hash response back (e.g. in the event of a 401)
      Hash.strhash(app)
    }
  end

  # TODO: refactor to `project`
  def app(id)
    response = HTTParty.get(File.join(Pakyow::Config.console.platform_url, 'api/projects', id.to_s), basic_auth: {
      username: @email,
      password: @token,
    })

    Hash.strhash(JSON.parse(response.body))
  end

  def events
    if app = @info[:project]
      response = HTTParty.get(File.join(Pakyow::Config.console.platform_url, "api/projects/#{app[:id]}", 'events'), basic_auth: {
        username: @email,
        password: @token,
      })

      JSON.parse(response.body).map { |event|
        event = Hash.strhash(event)
        event[:created_at] = DateTime.parse(event[:created_at]).to_time
        event
      }
    else
      []
    end
  end

  def collaborators
    if app = @info[:project]
      response = HTTParty.get(File.join(Pakyow::Config.console.platform_url, "api/projects/#{app[:id]}", 'collaborators'), basic_auth: {
        username: @email,
        password: @token,
      })

      body = Hash.strhash(JSON.parse(response.body))
      if body && !body.key?("error")
        body[:users].map { |u| Hash.strhash(u) }
        body[:invites].map { |i| Hash.strhash(i) }
        body
      else
        []
      end
    else
      []
    end
  end
  
  def create_collaborator(email)
    if app = @info[:project]
      response = HTTParty.post(File.join(Pakyow::Config.console.platform_url, "api/projects/#{app[:id]}", 'collaborators'), basic_auth: {
        username: @email,
        password: @token,
      }, body: { collaborator: { email: email } })
      
      Hash.strhash(JSON.parse(response.body))
    else
      {}
    end
  end
  
  def remove_collaborator(id)
    if app = @info[:project]
      response = HTTParty.delete(File.join(Pakyow::Config.console.platform_url, "api/projects/#{app[:id]}", 'collaborators', id), basic_auth: {
        username: @email,
        password: @token,
      })
    else
      {}
    end
  end

  def releases
    if app = @info[:project]
      response = HTTParty.get(File.join(Pakyow::Config.console.platform_url, "api/projects/#{app[:id]}", 'releases'), basic_auth: {
        username: @email,
        password: @token,
      })

      JSON.parse(response.body).map { |release|
        release = Hash.strhash(release)
        release[:created_at] = DateTime.parse(release[:created_at]).to_time
        release
      }
    end
  end

  def create_release
    response = HTTParty.post(File.join(Pakyow::Config.console.platform_url, 'api/projects', @info[:project][:id].to_s, 'releases'), basic_auth: {
      username: @email,
      password: @token,
    })

    Hash.strhash(JSON.parse(response.body))
  end

  def update_release(id, body)
    response = HTTParty.patch(File.join(Pakyow::Config.console.platform_url, 'api/projects', @info[:project][:id].to_s, 'releases', id.to_s), basic_auth: {
      username: @email,
      password: @token,
    }, body: { release: body })

    Hash.strhash(JSON.parse(response.body))
  end

  def file(id)
    response = HTTParty.get(File.join(Pakyow::Config.console.platform_url, 'api/projects', @info[:project][:id].to_s, 'files', id), basic_auth: {
      username: @email,
      password: @token,
    })

    response.body
  end

  def processed_file(id, params)
    response = HTTParty.get(File.join(Pakyow::Config.console.platform_url, 'api/projects', @info[:project][:id].to_s, 'files', id, 'processed'), body: params)
    response.body
  end

  def create_file(data, id: nil)
    uri = File.join(Pakyow::Config.console.platform_url, 'api/projects', @info[:project][:id].to_s, 'files')
    url = URI.parse(uri)

    data = if data.is_a?(String)
      StringIO.new(data)
    else
      data.open
      data
    end

    req = Net::HTTP::Post::Multipart.new url.path, "file" => UploadIO.new(data, 'image/jpeg', 'image.jpg'), "file_id" => id
    req.basic_auth @email, @token

    http = Net::HTTP.new(url.host, url.port)

    if url.is_a?(URI::HTTPS)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end

    http.request(req)
  end

  def remove_file(id)
    response = HTTParty.delete(File.join(Pakyow::Config.console.platform_url, 'api/projects', @info[:project][:id].to_s, 'files', id), basic_auth: {
      username: @email,
      password: @token,
    })
  end
end

class PlatformClient
  def initialize(email, token, info)
    @email = email
    @token = token
    @info  = info
  end

  def valid?
    response = HTTParty.get(File.join($platform_url, 'api/apps'), basic_auth: {
      username: @email,
      password: @token,
    })

    response.code == 200
  end

  def socket
    response = HTTParty.post(File.join($platform_url, 'api/apps', @info[:app][:id].to_s, 'socket'), basic_auth: {
      username: @email,
      password: @token,
    })

    Hash.strhash(JSON.parse(response.body))
  end

  def apps
    response = HTTParty.get(File.join($platform_url, 'api/apps'), basic_auth: {
      username: @email,
      password: @token,
    })

    JSON.parse(response.body).map { |app|
      Hash.strhash(app)
    }
  end

  def app(id)
    response = HTTParty.get(File.join($platform_url, 'api/apps', id.to_s), basic_auth: {
      username: @email,
      password: @token,
    })

    Hash.strhash(JSON.parse(response.body))
  end

  def events
    response = HTTParty.get(File.join($platform_url, "api/apps/#{@info[:app][:id]}", 'events'), basic_auth: {
      username: @email,
      password: @token,
    })

    JSON.parse(response.body).map { |event|
      event = Hash.strhash(event)
      event[:created_at] = DateTime.parse(event[:created_at]).to_time
      event
    }
  end

  def collaborators
    response = HTTParty.get(File.join($platform_url, "api/apps/#{@info[:app][:id]}", 'collaborators'), basic_auth: {
      username: @email,
      password: @token,
    })

    JSON.parse(response.body).map { |app|
      Hash.strhash(app)
    }
  end
end

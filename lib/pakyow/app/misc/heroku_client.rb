require 'platform-api'

class HerokuClient
  def initialize(token)
    @token = token
  end

  #TODO better way of checking validity?
  def valid?
    client.region.list
    true
  rescue
    false
  end

  def method_missing(method, *args)
    client.send(method, *args)
  end

  private

  def client
    @client ||= PlatformAPI.connect(@token)
  end
end

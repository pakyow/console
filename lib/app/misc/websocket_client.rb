require 'bundler/setup'
require 'websocket-client-simple'
require 'httparty'
require 'json'
require 'securerandom'

class WebSocketClient
  def initialize(context, platform_client, platform_info)
    @platform_client = platform_client
    @platform_info = platform_info

    socket.on :message do |msg|
      msg = Hash.strhash(JSON.parse(msg.data.to_s))

      if event = msg[:payload][:event]
        context.data(:app_event).mutated(event)
      end

      if collaborator = msg[:payload][:collaborator]
        context.data(:collaborator).mutated(collaborator)
      end

      if release = msg[:payload][:release]
        context.data(:release).mutated(release)
      end
    end

    socket.on :open do
      puts '!!! opened'
    end

    socket.on :close do |e|
      puts '!!! closed'
      # exit 1
    end

    socket.on :error do |e|
      puts '!!! error'
      puts e.message
      puts e.backtrace
    end
  end

  private

  def shutdown
    puts '!!! shutting down'
    socket.close
  end

  def socket
    return @socket if @socket
    info = @platform_client.socket
    @socket = WebSocket::Client::Simple.connect "ws://#{$platform_uri}?socket_connection_id=#{info[:socket_connection_id]}&socket_key=#{info[:socket_key]}"
  end
end

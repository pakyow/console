require 'websocket-client-simple'
require 'httparty'
require 'json'
require 'securerandom'
require 'concurrent'

class WebSocketClient
  def initialize(context, platform_client, platform_info)
    @platform_client = platform_client
    @platform_info = platform_info

    if ws = socket
      ws.on :message do |msg|
        msg = Hash.strhash(JSON.parse(msg.data.to_s))

        if payload = msg[:payload]
          if event = payload[:event]
            context.data(:app_event).mutated(event)
          end

          if collaborator = payload[:collaborator]
            context.data(:collaborator).mutated(collaborator)
          end

          if release = payload[:release]
            context.data(:release).mutated(release)
          end
        end
      end

      ws.on :open do
        puts '!!! opened'
      end

      ws.on :close do |e|
        puts '!!! closed'
        # exit 1
      end

      ws.on :error do |e|
        puts '!!! error'
        puts e.message
        puts e.backtrace
      end

      Concurrent::Future.execute do
        loop do
          sleep 15
          ws.send({ action: 'ping' }.to_json)
        end
      end
    end
  end

  private

  def shutdown
    puts '!!! shutting down'
    socket.close
  end

  def socket
    return if @platform_info.empty?
    return @socket if @socket
    info = @platform_client.socket
    @socket = WebSocket::Client::Simple.connect "ws://#{$platform_uri}?socket_connection_id=#{info[:socket_connection_id]}&socket_key=#{info[:socket_key]}"
  end
end

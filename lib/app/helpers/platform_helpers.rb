module Pakyow
  module Helpers
    module Platform
      include Pakyow::Helpers

      def platform_client(email = nil, token = nil)
        if email && token
          PlatformClient.new(email, token, platform_info)
        elsif Pakyow::Config.env == :development && !platform_creds.empty?
          PlatformClient.new(platform_creds[:email], platform_creds[:token], platform_info)
        elsif console_authed?
          PlatformClient.new(session[:platform_email], session[:platform_token], platform_info)
        end
      end

      def platform_creds
        return {} unless File.exists?(pakyow_platform_file_path)
        Hash.strhash(JSON.parse(File.open(pakyow_platform_file_path).read))
      end

      def pakyow_platform_file_path
        File.expand_path('~/.pakyow')
      end

      def setup_platform_socket(auth_info = nil)
        return if $socket
        return if (auth_info.nil? || auth_info.empty?) && !platform_authed?
        return if $platform_uri.nil?
        auth_info ||= { email: session[:platform_email], token: session[:platform_token] }
        $socket = WebSocketClient.new(self, platform_client(auth_info[:email], auth_info[:token]), auth_info)
      end
    end
  end
end

class Pakyow::App
  include Pakyow::Helpers::Platform
end

class Pakyow::CallContext
  include Pakyow::Helpers::Platform
end

class Pakyow::UI::Mutable
  include Pakyow::Helpers::Platform
end

require 'httparty'

module Pakyow::Helpers
  CONSOLE_SESSION_KEY = :console_user

  def using_platform?
    Pakyow::Config.console.use_pakyow_platform == true
  end

  def console_setup?
    platform_setup? || Pakyow::Console::User.count > 0
  end

  def platform_setup?
    File.exists?(platform_file_path)
  end

  def console_authed?
    !session[CONSOLE_SESSION_KEY].nil? || platform_authed?
  end

  def platform_authed?
    return false if req.nil?
    !session[:platform_email].nil? && !session[:platform_token].nil?
  end

  def console_auth(user)
    session[CONSOLE_SESSION_KEY] = user.id
  end

  def console_unauth
    session[CONSOLE_SESSION_KEY] = nil
    session[:platform_email] = nil
    session[:platform_token] = nil
    $socket = nil
  end

  def current_console_user
    if platform?
      { email: session[:platform_email] }
    else
      Pakyow::Console::User[session[CONSOLE_SESSION_KEY]]
    end
  end

  def platform?
    return unless console_authed?
    (platform_setup? && platform_client.valid?)
  end

  def platform_token?
    if File.exists?(pakyow_platform_file_path)
      email, token = platform_creds.values_at(:email, :token)

      if email.nil? || email.empty? || token.nil? || token.empty?
        return false
      else
        return true
      end
    else
      return false
    end
  end

  def platform_client(email = nil, token = nil)
    if email && token
      PlatformClient.new(email, token, platform_info)
    elsif Pakyow.app.env == :development && !platform_creds.empty?
      PlatformClient.new(platform_creds[:email], platform_creds[:token], platform_info)
    elsif console_authed?
      PlatformClient.new(session[:platform_email], session[:platform_token], platform_info)
    end
  end

  def platform_creds
    return {} unless File.exists?(pakyow_platform_file_path)
    Hash.strhash(JSON.parse(File.open(pakyow_platform_file_path).read))
  end

  def platform_info
    return {} unless File.exists?(platform_file_path)
    Hash.strhash(JSON.parse(File.open(platform_file_path).read))
  end

  def pakyow_platform_file_path
    File.expand_path('~/.pakyow')
  end

  def platform_file_path
    File.expand_path('./.platform')
  end

  def setup_platform_socket(auth_info = nil)
    return if $socket
    return if (auth_info.nil? || auth_info.empty?) && !platform_authed?
    return if $platform_uri.nil?
    auth_info ||= { email: session[:platform_email], token: session[:platform_token] }
    $socket = WebSocketClient.new(self, platform_client(auth_info[:email], auth_info[:token]), auth_info)
  end

  def reconnect_platform_socket(auth_info = nil)
    if $socket
      $socket.shutdown
      $socket = nil
    end

    setup_platform_socket(auth_info)
  end
end

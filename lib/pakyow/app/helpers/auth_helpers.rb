require 'httparty'

module Pakyow::Helpers
  CONSOLE_SESSION_KEY = :console_user

  def using_platform?
    Pakyow::Config.console.use_pakyow_platform == true
  end

  def console_setup?
    if using_platform?
      return platform_setup?
    else
      return Pakyow::Console.model(:user).count > 0
    end

    false
  end

  def platform_setup?
    File.exists?(platform_file_path)
  end

  def console_authed?
    !session[CONSOLE_SESSION_KEY].nil?
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
    user = Pakyow::Console.model(:user)[session[CONSOLE_SESSION_KEY]]
    return user if user && user.console?
    nil
  end

  def platform?
    return unless console_authed?
    platform_setup?
    # TODO: removed this valid check because performance
    # (platform_setup? && platform_client.valid?)
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

  def platform_info
    return {} unless File.exists?(platform_file_path)
    Hash.strhash(JSON.parse(File.open(platform_file_path).read))
  end

  def platform_file_path
    File.expand_path('./.platform')
  end

  def reconnect_platform_socket(auth_info = nil)
    if $socket
      $socket.shutdown
      $socket = nil
    end

    setup_platform_socket(auth_info)
  end

  def ensure_user_record_for_platform
    return if current_console_user

    user = Pakyow::Console.model(:user).new

    # TODO: fetch and set other user values (e.g. name, timezone, username)
    #   first need to create an api endpoint for fetching user information for the token

    user.email = session[:platform_email]
    user.role = Pakyow::Console.model(:user)::ROLES[:admin]
    user.save(validate: false)
  end
end

require 'httparty'

module Pakyow::Helpers
  def setup?
    File.exists?(platform_file_path) || Pakyow::Auth::User.count > 0
  end

  def authed?
    !session[:user].nil? || platform?
  end

  def current_user
    if platform?
      platform_creds
    else
      Pakyow::Auth::User[session[:user]]
    end
  end

  def platform?
    (setup? && platform_client.valid?)
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
    unless email && token
      email, token = platform_creds.values_at(:email, :token)
    end

    PlatformClient.new(email, token, platform_info)
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
end

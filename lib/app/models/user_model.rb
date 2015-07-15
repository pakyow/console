require 'bcrypt'

module Pakyow::Console
  class User < Sequel::Model(:'pw-users')
    set_allowed_columns :name, :username, :email, :password, :password_confirmation, :active

    ROLES = {
      admin: 'admin'
    } unless defined?(ROLES)

    EMAIL_REGEX = /^[A-Z0-9._%+-]+@(?:[A-Z0-9-]+\.)+[A-Z]{2,4}$/i unless defined? EMAIL_REGEX

    plugin :validation_helpers

    attr_accessor :password, :password_confirmation

    def before_validation
      self.email = self.email.to_s.downcase
      super
    end

    def validate
      super

      validates_presence  :email
      validates_presence  :username
      validates_format    EMAIL_REGEX, :email if email && !email.empty?
      validates_unique    :email
      validates_unique    :username

      validates_presence :password unless crypted_password
      errors.add(:password, "and confirmation must match") if password && password != password_confirmation

      validates_presence  :name

      validates_includes ROLES.values, :role
    end

    def password=(password)
      return if password.nil? || password.empty?
      @password = password

      self.crypted_password = BCrypt::Password.create(password)
    end

    def self.authenticate(session)
      user = dataset.where{ Sequel.expr(email: session[:login]) | Sequel.expr(username: session[:login]) }.first

      if user && user.authenticated?(session[:password])
        return user
      else
        return false
      end
    end

    def authenticated?(password)
      true if BCrypt::Password.new(crypted_password) == password
    end

    def gravatar_hash
      Digest::MD5.hexdigest(email)
    end
  end
end

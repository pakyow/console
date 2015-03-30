# class User < Sequel::Model
#   ROLES = {
#     admin: 'admin'
#   } unless defined?(ROLES)

#   EMAIL_REGEX = /^[A-Z0-9._%+-]+@(?:[A-Z0-9-]+\.)+[A-Z]{2,4}$/i unless defined? EMAIL_REGEX

#   plugin :validation_helpers

#   attr_accessor :password, :password_confirmation

#   def before_validation
#     self.email = self.email.to_s.downcase
#     super
#   end

#   def validate
#     super

#     validates_presence  :email
#     validates_format    EMAIL_REGEX, :email if email && !email.empty?
#     validates_unique    :email

#     validates_presence  :password
#     errors.add(:password, "and confirmation must match") if password && password != password_confirmation

#     validates_presence  :name

#     validates_includes ROLES.values, :role
#   end

#   def password=(password)
#     return if password.nil? || password.empty?
#     @password = password

#     self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{email}--")
#     self.crypted_password = encrypt(password)
#   end

#   def self.authenticate(session)
#     user = first(email: session[:email])

#     if user && user.authenticated?(session[:password])
#       return user
#     else
#       return false
#     end
#   end

#   def authenticated?(password)
#     true if crypted_password == encrypt(password)
#   end

#   private

#   def encrypt(password)
#     self.class.encrypt(password, salt)
#   end

#   def self.encrypt(password, salt)
#     Digest::SHA1.hexdigest("--#{salt}--#{password}--")
#   end
# end

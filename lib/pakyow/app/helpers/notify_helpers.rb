module Pakyow::Helpers
  def notify(message, type = :default, redirect: nil)
    prefix = case type
      when :success then '\o/'
      when :fail then ':('
      else ''
    end

    message = "#{prefix} #{message}"

    if req.socket? && !redirect
      res.header['Pakyow-Notify'] = message
      res.header['Pakyow-Notify-Type'] = type
    else
      session[:notify] = {
        type: type,
        message: message,
      }

      redirect redirect if redirect.is_a?(String)
    end
  end
end

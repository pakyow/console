module Pakyow::Helpers
  def notify(message, type = :default, redirect: nil)
    if req.socket? && !redirect
      res.header['Pakyow-Notify'] = message
      res.header['Pakyow-Notify-Type'] = type
    else
      session[:notify] = {
        type: type,
        message: message,
      }

      redirect redirect unless redirect.nil?
    end
  end
end

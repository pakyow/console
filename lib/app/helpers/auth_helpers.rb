module Pakyow::Helpers
  def setup?
    Pakyow::Auth::User.count > 0
  end
end

module Pakyow
  module Console
    module Models
      class Subscription < Sequel::Model(Pakyow::Config.app.db[:'pw-subscriptions'])
      end
    end
  end
end

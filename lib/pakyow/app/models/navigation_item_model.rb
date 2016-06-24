module Pakyow
  module Console
    module Models
      class NavigationItem < Sequel::Model(:'pw-navigation-items')
        many_to_one :navigation
        many_to_one :endpoint, polymorphic: true

        set_allowed_columns :navigation, :endpoint_id, :endpoint_type, :group
      end
    end
  end
end

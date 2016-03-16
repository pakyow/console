module Pakyow
  module Console
    module Models
      class Content < Sequel::Model(:'pw-content')
        many_to_one :owner, polymorphic: true

        def to_json
          content.to_json
        end
      end
    end
  end
end

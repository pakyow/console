module Pakyow
  module Console
    module Models
      class PlatformUser
        EMAIL_REGEX = /\A[A-Z0-9._%+-]+@(?:[A-Z0-9-]+\.)+[A-Z]{2,4}\z/i

        def self.all(platform_client)
          collabs = platform_client.collaborators

          data = []
          return data if collabs.empty?

          data.concat(collabs[:users].map { |user|
            datum = PlatformUser.new(user)
            datum.platform_client = platform_client
            datum.type = :user
            datum
          })
          
          data.concat(collabs[:invites].map { |invite|
            datum = PlatformUser.new(invite)
            datum.platform_client = platform_client
            datum.type = :invite
            datum
          })

          data
        end
        
        def self.find(id, platform_client)
          all(platform_client).find { |c| c.id == id }
        end
        
        attr_reader :values, :id, :email, :name, :username
        attr_accessor :type, :platform_client

        def initialize(values = {})
          @values = values
          set_all(values)
        end
        
        def set_all(values)
          @id, @email, @name, @username = values.values_at("id", "email", "name", "username")
        end
        
        def valid?
          EMAIL_REGEX =~ @email
        end
        
        def errors
          self
        end
        
        def full_messages
          # this is the only error we could ever have
          ["Sorry, that email address is invalid"]
        end
        
        def save(platform_client)
          collab = platform_client.create_collaborator(@email)
          @id = collab[:id]
        end
        
        def [](attr)
          instance_variable_get(:"@#{attr}")
        end
        
        def remove
          platform_client.remove_collaborator(id)
        end
      end
    end
  end
end

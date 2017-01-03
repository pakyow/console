module Pakyow
  module Console
    module Models
      class Collection < Sequel::Model(:'pw-collections')
        def matches?(path)
          String.normalize_path(path) == String.normalize_path(slug)
        end
        
        def published?
          published == true
        end
        
        def updated_at
          post = Pakyow::Console::Models::Post.where(published: true).first
          return @values[:updated_at] unless post
          post.updated_at
        end
      end
    end
  end
end

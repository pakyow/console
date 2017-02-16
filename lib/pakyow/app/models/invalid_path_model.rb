# module Pakyow
#   module Console
#     module Models
#       class InvalidPath < Sequel::Model(:'pw-invalid-paths')
#         def before_save
#           self.path = String.slugify(path)
#           super
#         end
#
#         def self.invalid_for_path?(path)
#           where(path: String.slugify(path)).count > 0
#         end
#       end
#     end
#   end
# end

require '/Users/bryanp/code/pakyow/libs/pakyow/pakyow-support/lib/pakyow-support'
require '/Users/bryanp/code/pakyow/libs/pakyow/pakyow-core/lib/pakyow-core'
require '/Users/bryanp/code/pakyow/libs/pakyow/pakyow-presenter/lib/pakyow-presenter'

require 'pakyow-slim'

require 'sass/plugin/compiler'

require 'sequel'
Sequel::Model.plugin :timestamps, update_on_create: true

CONSOLE_ROOT = File.expand_path('../', __FILE__)

#TODO need to be smarter about view reloading in development by keeping up with changed views
# it's currently taking a 5ms response to a 400ms one; might also be worth doing a performance audit
Pakyow::App.config.presenter.view_stores[:console] = File.join(CONSOLE_ROOT, 'views')
Pakyow::App.config.app.resources[:console] = File.join(CONSOLE_ROOT, 'resources')

module Sass
  module Plugin
    #HACK this fixes some sass bug
    def self.checked_for_updates=(*args)
    end
  end
end

module Pakyow
  module Console
    def self.sass
      @sass ||= Sass::Plugin::Compiler.new
    end

    def self.loader
      @loader ||= Pakyow::Loader.new
    end

    def self.load_paths
      @load_paths ||= []
    end

    def self.add_load_path(path)
      load_paths << path
    end

    def self.boot_plugins
      Plugins.boot
    end

    # def self.db
    #   @db ||= ROM.setup(:sql, "postgres://localhost/console")
    # end

    # def self.rom
    #   @rom ||= ROM.finalize.env
    # end
  end
end

# class ValidationError < StandardError
#   attr_reader :object

#   def initialize(object)
#     @object = object
#   end

#   def errors
#     @object.errors
#   end
# end

# module Pakyow
#   class Data
#     def self.inherited(subclass)
#       subclass.include(Virtus.model)
#       subclass.include(ActiveModel::Validations)

#       subclass.attribute(:created_at, Time)
#       subclass.attribute(:updated_at, Time)

#       name = Inflecto.tableize(subclass).to_sym

#       Pakyow::Console.db.relation(name) do; end

#       Pakyow::Console.db.commands(name) do
#         define :create do
#           validator subclass.validator
#           result :one
#         end

#         define :update do
#           validator subclass.validator
#           result :many
#         end

#         define :delete do
#           result :many
#         end
#       end

#       Pakyow::Console.db.mappers do
#         define(name) do
#           model subclass
#         end
#       end
#     end

#     def self.validator
#       proc { |attrs|
#         o = self.new(attrs)
#         raise ValidationError, o unless o.valid?
#       }
#     end
#   end
# end

require_relative 'plugins'
require_relative 'routes'
require_relative 'data'

require_relative 'core_plugin'

class String
  # returns string with first letter capitalized and the rest unmodified
  def self.capitalize(string)
    string.slice(0,1).capitalize + string.slice(1..-1)
  end
end

Pakyow::Console.sass.add_template_location(File.join(CONSOLE_ROOT, 'resources', 'console', 'scss'), File.join(CONSOLE_ROOT, 'resources', 'console', 'styles'))
Pakyow::Console.add_load_path(File.join(CONSOLE_ROOT, 'app'))
# Pakyow::Console.db

Pakyow::App.before :load do
  Pakyow::Console.boot_plugins
  Pakyow::Console.sass.update_stylesheets
  Pakyow::Console.load_paths.each do |path|
    Pakyow::Console.loader.load_from_path(path)
  end
end

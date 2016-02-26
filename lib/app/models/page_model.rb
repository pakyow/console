# TODO: this belongs in pakyow/support
class String
  def self.slugify(string)
    string.downcase.gsub('  ', ' ').gsub(' ', '-').gsub(/[^a-z0-9-]/, '')
  end
end

module Pakyow::Console
  class Page < Sequel::Model(:'pw-pages')
    many_to_one :parent, class: self
    alias_method :page, :parent

    set_allowed_columns :name, :parent, :template

    def validate
      validates_presence :name
      validates_presence :template

      # TODO: require unique slug (find a unique one automatically)
    end

    def before_create
      super
      self.slug = String.slugify(name)
    end

    def before_save
      return if @values[:content].is_a?(Sequel::Postgres::JSONHash)
      self.content = { default: @values[:content] }
    end

    def content
      @values[:content]['default']
    end

    def relation_name
      name
    end

    def matches?(path)
      # TODO: this needs to be smart enough to handle parent
      String.normalize_path(path) == slug
    end

    def published?
      published == true
    end
  end
end

# TODO: move to a more logical place
Pakyow::Console.after :page, :create do
  puts 'invalidating'
  Pakyow::Console.invalidate_pages
end

Pakyow::Console.after :page, :update do
  puts 'invalidating'
  Pakyow::Console.invalidate_pages
end

Pakyow::Console.after :page, :delete do
  puts 'invalidating'
  Pakyow::Console.invalidate_pages
end

Pakyow::Presenter::StringDocParser::SIGNIFICANT << :navigation?

module Pakyow
  module Presenter
    class StringDocParser
      private

      def navigation?(node)
        return false unless node.is_a?(Oga::XML::Element)
        return false unless node.attribute('data-navigation')
        return true
      end
    end

    class StringDoc
      def navigations
        find_navigations(@node ? [@node] : @structure)
      end

      private

      def find_navigations(structure, primary_structure = @structure, navigations = [])
        ret_navigations = structure.inject(navigations) { |s, e|
          if e[1].has_key?(:'data-navigation')
            s << {
              doc: StringDoc.from_structure(primary_structure, node: e),
              navigation: e[1][:'data-navigation'].to_sym,
            }
          end
          find_navigations(e[2], e[2], s)
          s
        } || []

        ret_navigations
      end
    end
  end
end

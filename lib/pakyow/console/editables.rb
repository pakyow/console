Pakyow::Presenter::StringDocParser::SIGNIFICANT << :editable?
Pakyow::Presenter::StringDocParser::SIGNIFICANT << :editable_part?

module Pakyow
  module Presenter
    class StringDocParser
      private

      def editable?(node)
        return false unless node.is_a?(Oga::XML::Element)
        return false unless node.attribute('data-editable')
        return true
      end

      def editable_part?(node)
        return false unless node.is_a?(Oga::XML::Element)
        return false unless node.attribute('data-editable-part')
        return true
      end
    end

    class StringDoc
      def editables
        find_editables(@node ? [@node] : @structure)
      end

      def editable_parts
        find_editable_parts(@node ? [@node] : @structure)
      end

      private

      def find_editables(structure, primary_structure = @structure, editables = [])
        ret_editables = structure.inject(editables) { |s, e|
          if e[1].has_key?(:'data-editable')
            s << {
              doc: StringDoc.from_structure(primary_structure, node: e),
              editable: e[1][:'data-editable'].to_sym,
            }
          end
          find_editables(e[2], e[2], s)
          s
        } || []

        ret_editables
      end

      def find_editable_parts(structure, primary_structure = @structure, editable_parts = [])
        ret_editable_parts = structure.inject(editable_parts) { |s, e|
          if e[1].has_key?(:'data-editable-part')
            s << {
              doc: StringDoc.from_structure(primary_structure, node: e),
              editable_part: e[1][:'data-editable-part'].to_sym,
            }
          end
          find_editable_parts(e[2], e[2], s)
          s
        } || []

        ret_editable_parts
      end
    end
  end
end

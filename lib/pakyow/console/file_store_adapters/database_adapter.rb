module Pakyow
  module Console
    class DBFileAdapter
      def store(tempfile, metadata)
        file = find(metadata[:id], w: metadata[:width], h: metadata[:height], m: metadata[:mode])
        return unless file.nil?

        file = Pakyow::Console::Models::StoredFile.new
        file.data = tempfile.read
        file.metadata = metadata
        file.save
      end

      def find(hash, w: nil, h: nil, m: nil)
        file = find_object(hash, w: w, h: h, m: m)
        return if file.nil?

        Hash.strhash(file.metadata)
      end

      def processed(hash, w: nil, h: nil, m: nil)
        file = find_object(hash, w: w, h: h, m: m)
        return if file.nil?
        file.data
      end

      def process(metadata, data, w: nil, h: nil)
        file = Pakyow::Console::Models::StoredFile.new
        file.data = data
        file.metadata = metadata
        file.save
      end

      def data(hash)
        file = find_object(hash)
        return if file.nil?
        file.data
      end

      def all
        Pakyow::Console::Models::StoredFile.all.map { |file|
          Hash.strhash(file.metadata)
        }
      end

      protected

      def find_object(hash, w: nil, h: nil, m: nil)
        query = Pakyow::Console::Models::StoredFile.where("(metadata ->> 'id') = '#{hash}'").order(:created_at)
        query = query.where("(metadata ->> 'width') = '#{w}'") unless w.nil?
        query = query.where("(metadata ->> 'height') = '#{h}'") unless h.nil?
        query = query.where("(metadata ->> 'mode') = '#{m}'") unless m.nil?
        query.first
      end
    end
  end
end

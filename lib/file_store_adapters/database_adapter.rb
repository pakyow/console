module Pakyow
  module Console
    class DBFileAdapter
      def store(tempfile, metadata)
        file = find(metadata[:id], w: metadata[:width], h: metadata[:height])
        return unless file.nil?

        file = StoredFile.new
        file.data = tempfile.read
        file.metadata = metadata
        file.save
      end

      def delete(id)
        StoredFile.where("(metadata ->> 'id') = '#{id}'").delete
      end

      def find(hash, w: nil, h: nil)
        file = find_object(hash, w: w, h: h)
        return if file.nil?

        Hash.strhash(file.metadata)
      end

      def processed(hash, w: nil, h: nil)
        file = find_object(hash, w: w, h: h)
        return if file.nil?
        file.data
      end

      def process(metadata, data, w: nil, h: nil)
        file = StoredFile.new
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
        StoredFile.all.map { |file|
          Hash.strhash(file.metadata)
        }
      end

      protected

      def find_object(hash, w: nil, h: nil)
        query = StoredFile.where("(metadata ->> 'id') = '#{hash}'").order(:created_at)
        query = query.where("(metadata ->> 'width') = '#{w}'") unless w.nil?
        query = query.where("(metadata ->> 'height') = '#{h}'") unless h.nil?
        query.first
      end
    end
  end
end

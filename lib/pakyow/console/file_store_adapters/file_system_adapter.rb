module Pakyow
  module Console
    class FileSystemAdapter
      SKIPPED = ['.', '..', '.DS_Store', 'thumbnails', 'processed']

      def initialize
        @store_path = Pakyow::Config.console.file_storage_path
      end

      def store(tempfile, metadata)
        unless Dir.exists?(@store_path)
          Dir.mkdir(@store_path)
        end

        # TODO: check for existence of hash before blindly moving

        file_path = File.join(@store_path, metadata[:id])
        metadata[:path] = file_path + metadata[:ext]
        FileUtils.copy(tempfile.path, file_path + metadata[:ext])
        File.write(file_path + '.yml', metadata.to_yaml)

        reset
      end

      def process(file, processed_data, w: nil, h: nil, m: nil)
        path = processed_path(file[:id], w: w, h: h, m: m)
        File.open(processed_path(file[:id], w: w, h: h, m: m), 'wb+') do |f|
          f.write(processed_data)
        end
      end

      def find(hash)
        files.find { |f| f[:id] == hash }
      end

      def processed(hash, w: nil, h: nil, m: nil)
        path = processed_path(hash, w: w, h: h, m: m)
        return nil unless File.exists?(path)
        File.read(path)
      end

      def data(hash)
        File.open(find(hash)[:path], 'rb')
      end

      def all
        files
      end

      private

      def reset
        @files = nil
      end

      def load
        Dir.entries(@store_path).map { |file|
          next if SKIPPED.include?(file) || File.extname(file) == '.yml'

          config_file = File.join(@store_path, file.split('.')[0..-2].join('.') + '.yml')
          metadata = YAML::load_file(config_file)
        }.reject(&:nil?)
      end

      def files
        @files ||= load
      end

      def processed_path(hash, w: nil, h: nil, m: nil)
        file = find(hash)

        ext = file[:ext]
        path = file[:id]

        processed_path = File.join(@store_path, 'processed')
        sized_path = File.join(processed_path, path)

        Dir.mkdir(processed_path) unless Dir.exists?(processed_path)
        Dir.mkdir(sized_path)     unless Dir.exists?(sized_path)

        File.join(sized_path, w.to_s + 'x' + h.to_s + (m ? "-#{m}" : '') + ext)
      end
    end
  end
end

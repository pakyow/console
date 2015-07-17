require 'mini_magick'

module Pakyow::Console
  class FileStore
    include Singleton

    SKIPPED = ['.', '..', '.DS_Store', 'thumbnails', 'processed']

    def self.type_for_ext(ext)
      case ext.downcase
      when '.png', '.gif', '.jpg', '.jpeg'
        'image'
      when '.mp4', '.webm', '.ogv'
        'video'
      when '.mp3', '.wav'
        'audio'
      end
    end

    def initialize
      @store_path = Pakyow::Config.console.file_storage_path
    end

    def store!(filename, tempfile)
      #TODO raise exception rather than return
      return if filename.nil? || tempfile.nil?

      unless Dir.exists?(@store_path)
        Dir.mkdir(@store_path)
      end

      ext = File.extname(filename).downcase

      id = SecureRandom.uuid
      file_path = File.join(@store_path, id)
      File.open(file_path + ext, 'wb') { |f| f.write(tempfile.read) }

      type = self.class.type_for_ext(ext)

      width, height = case type
      when 'image'
        s = ImageSize.new(File.open(file_path + ext))
        [s.width, s.height]
      when 'video'
        [0, 0] #TODO determine video size
      end

      config = {
        id: id,
        path: file_path + ext,
        filename: filename,
        size: File.size(file_path + ext),
        ext: ext,
        type: type,
      }

      config[:width] = width unless width.nil?
      config[:height] = height unless height.nil?

      File.write(file_path + '.yml', config.to_yaml)

      reset

      config
    end

    def find(id)
      files.find { |f| f[:id] == id }
    end

    def files
      @files ||= load
    end

    def process(id, w: nil, h: nil)
      file = find(id)

      return unless file[:type] == 'image'

      ext = file[:ext]

      path = id
      processed_path = File.join(@store_path, 'processed')
      sized_path = File.join(processed_path, path)

      Dir.mkdir(processed_path) unless Dir.exists?(processed_path)
      Dir.mkdir(sized_path)     unless Dir.exists?(sized_path)

      new_path = File.join(sized_path, w.to_s + 'x' + h.to_s + ext)

      unless File.exists?(new_path)
        image = MiniMagick::Image.open(File.join(@store_path, path + ext))
        image.resize "#{w}x#{h}^"
        image.combine_options do |i|
          i.gravity "center"
          i.extent "#{w}x#{h}"
        end
        image.write new_path
      end

      File.open(new_path)
    end

    private

    def reset
      @files = nil
    end

    def load
      Dir.entries(@store_path).map { |file|
        next if SKIPPED.include?(file) || File.extname(file) == '.yml'

        config_file = File.join(@store_path, file.split('.')[0..-2].join('.') + '.yml')
        YAML::load_file(config_file)
      }.reject(&:nil?)
    end
  end
end

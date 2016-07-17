require 'mini_magick'
require 'fileutils'

require_relative 'file_store_adapters/database_adapter'
require_relative 'file_store_adapters/file_system_adapter'
require_relative 'file_store_adapters/platform_adapter'

module Pakyow::Console
  class FileStore
    include Singleton

    CONTEXT_MEDIA = 'media'
    CONTEXT_THUMB = 'thumb'
    CONTEXT_APP   = 'app'

    DEFAULT_MODE = :fill

    def self.type_for_ext(ext)
      case ext.downcase
      when '.png', '.gif', '.jpg', '.jpeg'
        'image'
      when '.mp4', '.webm', '.ogv'
        'video'
      when '.mp3', '.wav'
        'audio'
      else
        'unknown'
      end
    end

    def initialize
      @adapter = Pakyow::Config.console.file_store_adapter.new
    end

    def store(filename, tempfile, store_context: CONTEXT_APP, request_context: nil)
      #TODO raise exception rather than return
      return if filename.nil? || tempfile.nil?

      ext = File.extname(filename).downcase
      type = self.class.type_for_ext(ext)
      hash = Digest::MD5.file(tempfile).hexdigest

      width, height = case type
      when 'image'
        size = ImageSize.new(tempfile)
        [size.width, size.height]
      end

      metadata = {
        id: hash,
        filename: filename,
        size: File.size(tempfile),
        ext: ext,
        type: type,
        context: store_context,
      }

      metadata[:width] = width unless width.nil?
      metadata[:height] = height unless height.nil?

      @adapter.store(tempfile, metadata, request_context: request_context)

      # always return the metadata
      metadata
    end

    def find(hash)
      @adapter.find(hash)
    end

    def all
      @adapter.all
    end

    def processed(hash, w: nil, h: nil, m: nil, request_context: nil)
      file = find(hash).dup
      return if file[:type] != 'image'

      processed = @adapter.processed(file[:id], w: w, h: h, m: m, request_context: request_context)
      return processed unless processed.nil?

      file[:width] = w
      file[:height] = h
      file[:context] = CONTEXT_THUMB

      process(file, w: w, h: h, m: m, request_context: request_context)
    end

    def process(file, w: nil, h: nil, m: nil, request_context: nil)
      # TODO: this is the same image processor as in platform; abstract into a gem
      image = MiniMagick::Image.read(@adapter.data(file[:id], request_context: request_context))
      m = DEFAULT_MODE if m.nil? || m.empty?
      m = m.to_sym

      file['mode'] = m

      if m == :fit
        image.resize "#{w}x#{h}"
      elsif m == :fill
        image.resize "#{w}x#{h}^"
        image.combine_options do |i|
          i.gravity "center"
          i.extent "#{w}x#{h}"
        end
      elsif m == :pad
        image.combine_options do |cmd|
          cmd.thumbnail "#{w}x#{h}>"
          cmd.background "rgba(255, 255, 255, 0.0)"
          cmd.gravity "center"
          cmd.extent "#{w}x#{h}"
        end
      elsif m == :limit
        image.resize "#{w}x#{h}>"
      end

      data = image.to_blob
      @adapter.process(file, data, w: w, h: h, request_context: request_context)

      # always return the processed data
      data
    end

    def data(hash, request_context: nil)
      @adapter.data(hash, request_context: request_context)
    end
  end
end

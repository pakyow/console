module Pakyow
  module Console
    # A FileStore adapter for storing files in Pakyow Platform.
    #
    class PlatformFileAdapter
      def store(tempfile, metadata, request_context: nil)
        return if find(metadata['id'], w: metadata['width'], h: metadata['height'], m: metadata['mode'])
        raise ArgumentError, 'Expected a valid request context' if request_context.nil?

        client = PlatformClient.new(*client_info_from_request_context(request_context))

        # we don't pass the id here since it's the original file
        # platform will automatically use the MD5 digest as the id
        client.create_file(tempfile)

        file = Pakyow::Console::Models::StoredFile.new
        file.metadata = metadata
        file.save
      end

      def processed(hash, w: nil, h: nil, m: nil, request_context: nil)
        metadata = {
          'w' => w,
          'h' => h,
          'm' => m
        }

        client = PlatformClient.new(*client_info_from_request_context(request_context))
        client.processed_file(hash, metadata)
      end

      # NOTE: this isn't needed since all image processing happens in platform
      # def process(metadata, data, w: nil, h: nil, m: nil, request_context: nil)
      #   c_metadata = {
      #     'id' => metadata['id'],
      #     'width' => w,
      #     'height' => h,
      #     'mode' => m
      #   }

      #   client = PlatformClient.new(*client_info_from_request_context(request_context))
      #   client.create_file(data, id: id_for_metadata(c_metadata))

      #   file = Pakyow::Console::Models::StoredFile.new
      #   file.metadata = metadata
      #   file.save
      # end

      def data(hash, request_context: nil)
        file = find_object(hash)
        return if file.nil?

        client = PlatformClient.new(*client_info_from_request_context(request_context))
        client.file(file.metadata['id'])
      end

      def all
        Pakyow::Console::Models::StoredFile.all.map { |file|
          Hash.strhash(file.metadata)
        }
      end

      def find(hash, w: nil, h: nil, m: nil)
        file = find_object(hash, w: w, h: h, m: m)
        return if file.nil?

        Hash.strhash(file.metadata)
      end

      protected

      def find_object(hash, w: nil, h: nil, m: nil)
        query = Pakyow::Console::Models::StoredFile.where("(metadata ->> 'id') = '#{hash}'").order(:created_at)
        query = query.where("(metadata ->> 'width') = '#{w}'") unless w.nil?
        query = query.where("(metadata ->> 'height') = '#{h}'") unless h.nil?
        query = query.where("(metadata ->> 'mode') = '#{m}'") unless m.nil?
        query.first
      end

      def client_info_from_request_context(context)
        user = context.current_console_user
        return ['', '', context.platform_info] if user.nil?

        [user.platform_token, user.platform_token_secret, context.platform_info]
      end

      def id_for_metadata(metadata)
        id, w, h, m = metadata.values_at('id', 'width', 'height', 'mode')
        id + '-' + w.to_s + 'x' + h.to_s + (m ? "-#{m}" : '')
      end
    end
  end
end

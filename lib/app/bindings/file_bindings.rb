Pakyow::App.bindings :'console-file' do
  scope :file do
    binding :thumbnail do
      src = case bindable[:type]
      when 'image'
        "/console/files/#{bindable[:id]}?w=175&h=175"
      when 'video'
        '/console/images/thumbnail-video.png'
      when 'audio'
        '/console/images/thumbnail-audio.png'
      else
        '/console/images/thumbnail-default.png'
      end

      {
        style: {
          :'background-image' => "url(#{src})"
        }
      }
    end

    binding :filesize do
      "#{bindable[:size] / 1024}KB"
    end

    binding :type_class do
      { class: lambda { |c| c << bindable[:type] } }
    end

    binding :delete_href do
      { href: "/console/files/#{bindable[:id]}" }
    end
  end
end

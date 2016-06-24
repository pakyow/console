module Pakyow::Helpers
  def releasable?
    if info = release_info
      heroku_client(info[:token]).valid?
    else
      false
    end
  end

  def heroku_client(token = release_info[:token])
    @heroku_client ||= HerokuClient.new(token)
  end

  def release_info
    file = File.expand_path('./.platform-private')
    return nil unless File.exists?(file)
    Hash.strhash(JSON.parse(File.open(file).read))[:release]
  end
end

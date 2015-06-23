require 'securerandom'

class ReleaseAgent
  include Celluloid::IO
  finalizer :shutdown

  DEPLOY_PATH = File.expand_path('./')
  ADDONS = [
    'heroku-postgresql:hobby-dev',
    'heroku-redis:test',
  ]

  attr_reader :heroku_client, :platform_client, :release_object

  def initialize(heroku_client, platform_client, release_object)
    @heroku_client = heroku_client
    @platform_client = platform_client
    @release_object = release_object

    @id = SecureRandom.hex(10)
    async.perform
  end

  def perform
    log 'performing a new release'
    setup
    release
  end

  def setup
    return if setup?

    log 'getting things set up'

    app = heroku_client.app.create({})
    path = File.expand_path('./.platform')
    config = Hash.strhash(JSON.parse(File.open(path).read))
    config[:release] = { app: app }
    f = File.open(path, 'w')
    f.write(config.to_json)
    f.close

    ADDONS.each do |name|
      log "provisioning addon for #{app['id']}: #{name}"
      heroku_client.addon.create(app['id'], {
        plan: name
      })
    end

    log 'setup complete'
  end

  def release
    log 'doing the release'
    platform_client.update_release(release_object[:id], { status: :pending })

    source = create_source(DEPLOY_PATH)

    config = Hash.strhash(JSON.parse(File.open(File.expand_path('./.platform')).read))[:release][:app]

    log 'turning on maintenance mode'
    heroku_client.app.update(config[:id], { maintenance: true })

    log 'creating the build'
    build = Hash.strhash(heroku_client.build.create(config[:id], {
      source_blob: {
        url: source[:source_blob][:get_url]
      }
    }))

    while true
      sleep 1
      info = Hash.strhash(heroku_client.build.info(config[:id], build[:id]))
      log "build status: #{info[:status]}"
      break if info[:status] != 'pending'
    end
    log 'finished the build'

    log 'running db:migrate'
    dyno = Hash.strhash(heroku_client.dyno.create(config[:id], {
      command: 'bundle exec rake db:migrate'
    }))

    while true
      sleep 1
      begin
        Hash.strhash(heroku_client.dyno.info(config[:id], dyno[:id]))
      rescue
        log 'finished db:migrate'
        break
      end
    end

    log 'turning off maintenance mode'
    heroku_client.app.update(config[:id], { maintenance: false })
    platform_client.update_release(release_object[:id], { status: :done })
    log 'DONE'
    terminate
  end

  private

  def shutdown
  end

  def setup?
    config = Hash.strhash(JSON.parse(File.open(File.expand_path('./.platform')).read))
    config.key?('release')
  end

  def create_source(path)
    log 'making the build'

    `cd #{path} && tar -czf build.tgz ./*`

    filepath = File.join(path, 'build.tgz')

    log 'creating the source'
    config = Hash.strhash(JSON.parse(File.open(File.expand_path('./.platform')).read))[:release][:app]
    #TODO do this via httparty since not possible through platform-api
    source = Hash.strhash(JSON.parse(`curl -n -X POST https://api.heroku.com/apps/#{config[:id]}/sources -H 'Accept: application/vnd.heroku+json; version=3'`))

    log 'uploading the source'
    # perform the upload
    #TODO do this via httparty since not possible through platform-api
    `curl \"#{source[:source_blob][:put_url]}\" -X PUT -H 'Content-Type:' --data-binary @#{filepath}`

    log 'removing the local build'
    FileUtils.rm(filepath)

    source
  end

  def log(message)
    Pakyow.logger.debug "[Release #{@id}] #{message}"
  end
end

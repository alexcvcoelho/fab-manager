# frozen_string_literal: true

require 'sidekiq'
require 'sidekiq-scheduler'
require 'sidekiq/middleware/i18n'
require 'sidekiq/server_locale'

redis_host = ENV.fetch('REDIS_HOST', 'localhost')
redis_url = ENV.fetch('REDIS_CONNECTION_URL', "redis://#{redis_host}:6379")
# redis_password = ENV.fetch('REDIS_PASSWORD', nil)
# redis_ssl = ENV.fetch('REDIS_SSL', false)

Sidekiq.configure_server do |config|
  config.redis = { url: redis_url, ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE } }

  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
  end

  config.server_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Server
  end

  SidekiqUniqueJobs::Server.configure(config)

  config.on(:startup) do
    # load sidekiq-scheduler schedule config
    schedule_file = 'config/schedule.yml'
    if File.exist?(schedule_file)
      rendered_schedule_file = ERB.new(File.read(schedule_file)).result
      Sidekiq.schedule = YAML.safe_load(rendered_schedule_file)
      SidekiqScheduler::Scheduler.instance.reload_schedule!
    end
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: redis_url, ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE } }

  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
  end
  config.server_middleware do |chain|
    chain.add FabManager::Middleware::ServerLocale
  end
end

# Quieting logging in the test environment
if Rails.env.test?
  require 'sidekiq/testing'
  Sidekiq.logger.level = Logger::ERROR
end

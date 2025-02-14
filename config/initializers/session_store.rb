# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

redis_host = ENV.fetch('REDIS_HOST', 'localhost')
redis_connection_url = ENV.fetch('REDIS_CONNECTION_URL', "redis://#{redis_host}:6379")
# redis_password = ENV.fetch('REDIS_PASSWORD', nil)
# redis_ssl = ENV.fetch('REDIS_SSL', false)

Rails.application.config.session_store :redis_session_store,
                                       redis: {
                                         expire_after: 14.days,  # cookie expiration
                                         ttl: 14.days,           # Redis expiration, defaults to 'expire_after'
                                         key_prefix: 'fabmanager:session:',
                                         url: redis_connection_url
                                         #  password: redis_password,
                                         #  ssl: redis_ssl
                                       },
                                       key: '_Fab-manager_session',
                                       secure: (Rails.env.production? || Rails.env.staging?) &&
                                               !Rails.application.secrets.allow_insecure_http

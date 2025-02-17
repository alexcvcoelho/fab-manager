# frozen_string_literal: true

require 'active_support/core_ext/integer/time'

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded any time
  # it changes. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable server timing
  config.server_timing = true

  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.
  if Rails.root.join('tmp/caching-dev.txt').exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true

    config.cache_store = :memory_store
    config.public_file_server.headers = {
      'Cache-Control' => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = true

  config.action_mailer.perform_caching = false

  config.action_mailer.delivery_method = :smtp

  config.action_mailer.raise_delivery_errors = true

  puts "SMTP ADDRESS: #{Rails.application.secrets.smtp_address}"
  puts "SMTP PORT: #{Rails.application.secrets.smtp_port}"
  puts "SMTP USER NAME: #{Rails.application.secrets.smtp_user_name}"
  puts "SMTP PASSWORD: #{Rails.application.secrets.smtp_password}"
  puts "SMTP AUTHENTICATION: #{Rails.application.secrets.smtp_authentication}"
  puts "SMTP ENABLE STARTTLS AUTO: #{Rails.application.secrets.smtp_enable_starttls_auto}"
  puts "SMTP OPENSSL VERIFY MODE: #{Rails.application.secrets.smtp_openssl_verify_mode}"
  puts "SMTP TLS: #{Rails.application.secrets.smtp_tls}"
  puts "SMTP_DOMAIN: #{Rails.application.secrets.smtp_domain}"
  
  config.action_mailer.smtp_settings = {  
    address: Rails.application.secrets.smtp_address,
    port: Rails.application.secrets.smtp_port,
    user_name: Rails.application.secrets.smtp_user_name,
    password: Rails.application.secrets.smtp_password,
    authentication: Rails.application.secrets.smtp_authentication,
    enable_starttls_auto: Rails.application.secrets.smtp_enable_starttls_auto,
    openssl_verify_mode: Rails.application.secrets.smtp_openssl_verify_mode,
    domain: Rails.application.secrets.smtp_domain,
    tls: Rails.application.secrets.smtp_tls,
    ca_file: Rails.application.secrets.smtp_ca_file,
    ca_path: Rails.application.secrets.smtp_ca_path
  }

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Raises error for missing translations.
  # config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names.
  # config.action_view.annotate_rendered_view_with_filenames = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  config.log_level = Rails.application.secrets.log_level || :debug

  config.action_controller.default_url_options = {
    host: Rails.application.secrets.default_host,
    protocol: Rails.application.secrets.default_protocol
  }

  # whitelist IP for web-console: local network, docker and vagrant
  config.web_console.permissions = %w[192.168.0.0/16 192.168.99.0/16 10.0.2.2]

  config.hosts << ENV.fetch('DEFAULT_HOST', 'localhost')

  # https://github.com/flyerhzm/bullet
  # In development, Bullet will find and report N+1 DB requests
  config.after_initialize do
    Bullet.enable        = true
    Bullet.alert         = true
    Bullet.bullet_logger = true
    Bullet.console       = true
    Bullet.rails_logger  = true
    Bullet.add_footer    = true
  end
end

# config/environments/staging.rb

require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # ---------------------------------------------------------------------------
  # Code loading
  # ---------------------------------------------------------------------------
  config.enable_reloading = false
  config.eager_load = true

  # ---------------------------------------------------------------------------
  # Errors & caching
  # ---------------------------------------------------------------------------
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  # Serve static files (assets) from the app server if needed.
  # For Kamal/Docker, this is often controlled by RAILS_SERVE_STATIC_FILES.
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }

  # Cache store
  # - Default: memory_store (simple for staging)
  # - Override: CACHE_STORE=redis + REDIS_URL=... if you want prod-like behavior
  cache_store = ENV.fetch("CACHE_STORE", "memory").downcase
  case cache_store
  when "redis"
    redis_url = ENV.fetch("REDIS_URL", nil)
    if redis_url
      config.cache_store = :redis_cache_store, { url: redis_url }
    else
      # Fallback if redis requested but URL missing
      config.cache_store = :memory_store
    end
  else
    config.cache_store = :memory_store
  end

  # ---------------------------------------------------------------------------
  # Logging
  # ---------------------------------------------------------------------------
  config.log_tags = [:request_id]
  config.logger = ActiveSupport::TaggedLogging.logger(STDOUT)
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Prevent health checks from clogging up the logs.
  config.silence_healthcheck_path = "/up"

  # Don't log any deprecations in staging by default
  config.active_support.report_deprecations = false

  # ---------------------------------------------------------------------------
  # Active Storage
  # ---------------------------------------------------------------------------
  # Use Cloudflare R2 for staging; can override via ACTIVE_STORAGE_SERVICE env var
  config.active_storage.service = ENV.fetch("ACTIVE_STORAGE_SERVICE", "staging_r2").to_sym

  # ---------------------------------------------------------------------------
  # Action Mailer (safe by default)
  # ---------------------------------------------------------------------------
  # IMPORTANT:
  # - By default, staging will NOT send real emails.
  # - Turn on by setting MAIL_DELIVERIES=true and configuring RESEND/SMTP env.
  config.action_mailer.perform_deliveries = ENV["MAIL_DELIVERIES"] == "true"
  config.action_mailer.raise_delivery_errors = false

  # Prefer Resend (as you had), but keep it behind the delivery toggle above.
  # If you use SMTP instead, switch delivery_method + settings accordingly.
  config.action_mailer.delivery_method = ENV.fetch("MAIL_DELIVERY_METHOD", "resend").to_sym

  # Host/protocol used in mailer links
  config.action_mailer.default_url_options = {
    host: ENV.fetch("APP_HOST", "staging.thembooking.com"),
    protocol: ENV.fetch("APP_PROTOCOL", "https")
  }

  # SMTP settings (only used if MAIL_DELIVERY_METHOD=smtp)
  config.action_mailer.smtp_settings = {
    address: ENV.fetch("SMTP_ADDRESS", "smtp.gmail.com"),
    port: ENV.fetch("SMTP_PORT", 587).to_i,
    user_name: ENV.fetch("SMTP_USERNAME") { Rails.application.credentials.dig(:smtp, :username) },
    password: ENV.fetch("SMTP_PASSWORD") { Rails.application.credentials.dig(:smtp, :password) },
    authentication: :plain,
    enable_starttls_auto: true
  }

  # ---------------------------------------------------------------------------
  # I18n
  # ---------------------------------------------------------------------------
  config.i18n.fallbacks = true

  # ---------------------------------------------------------------------------
  # Active Record
  # ---------------------------------------------------------------------------
  config.active_record.dump_schema_after_migration = false
  config.active_record.attributes_for_inspect = [:id]

  # ---------------------------------------------------------------------------
  # Host Authorization (avoid staging surprises)
  # ---------------------------------------------------------------------------
  # Allow the staging host and (optionally) direct IP access.
  app_host = ENV.fetch("APP_HOST", "staging.thembooking.com")
  config.hosts << app_host

  # If you access staging via IP (e.g., http://1.2.3.4), allow IP hosts:
  if ENV["ALLOW_IP_HOSTS"] == "true"
    config.hosts << /(\A|\.)\d{1,3}(\.\d{1,3}){3}\z/
  end

  # If you use multiple subdomains for staging (e.g., *.staging.thembooking.com):
  if (host_regex = ENV["APP_HOST_REGEX"]).present?
    config.hosts << Regexp.new(host_regex)
  end

  # Optionally exclude the health check endpoint from host authorization
  config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
end

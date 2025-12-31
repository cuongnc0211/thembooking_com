# ActiveStorage configuration for Cloudflare R2 integration

# Cloudflare R2 doesn't fully support AWS SDK default checksum behavior
# Apply compatibility settings for all R2 environments (development, staging, production)
if Rails.env.development? || Rails.env.staging? || Rails.env.production?
  require 'aws-sdk-s3'

  # Base R2 compatibility settings
  r2_config = {
    http_wire_trace: false,
    log_level: :warn,
    # R2 compatibility: Don't use checksums that R2 doesn't support
    # This prevents "You can only specify one non-default checksum at a time" errors
    compute_checksums: false
  }

  # Development-specific settings (SSL verification issues on macOS)
  if Rails.env.development?
    r2_config[:ssl_verify_peer] = false
    Rails.logger.info "⚠️  AWS SDK configured for Cloudflare R2 (development mode - SSL verification disabled)"
  else
    Rails.logger.info "✅ AWS SDK configured for Cloudflare R2 (#{Rails.env} mode)"
  end

  Aws.config.update(r2_config)
end

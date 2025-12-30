# ActiveStorage configuration for Cloudflare R2 integration

# Fix SSL certificate verification issues in development
# (Common issue with aws-sdk-s3 and Cloudflare R2 on macOS)
if Rails.env.development?
  require 'aws-sdk-s3'

  Aws.config.update(
    http_wire_trace: false,
    log_level: :warn,  # Reduce logging noise
    # Disable SSL verification in development only (fixes CRL certificate errors)
    ssl_verify_peer: false,
    # R2 compatibility: Don't use checksums that R2 doesn't support
    compute_checksums: false
  )

  Rails.logger.info "⚠️  AWS SDK configured for Cloudflare R2 (development mode)"
end

class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # Set timezone for all requests
  around_action :set_time_zone, if: :authenticated?

  # Set locale for all requests
  before_action :set_locale

  # Helper to get current user (returns nil if not authenticated)
  def current_user
    Current.user
  end
  helper_method :current_user

  private

  def set_time_zone(&block)
    Time.use_zone(Current.user.time_zone, &block)
  end

  def set_locale
    I18n.locale = session[:locale] || extract_locale_from_accept_language_header || I18n.default_locale
  end

  def extract_locale_from_accept_language_header
    return nil unless request.env["HTTP_ACCEPT_LANGUAGE"]

    request.env["HTTP_ACCEPT_LANGUAGE"].scan(/^[a-z]{2}/).first&.to_sym.tap do |locale|
      return nil unless I18n.available_locales.include?(locale)
    end
  end
end

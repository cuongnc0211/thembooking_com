class LocalesController < ApplicationController
  skip_before_action :require_authentication, only: [:update]

  def update
    locale = params[:locale]&.to_sym

    if I18n.available_locales.include?(locale)
      session[:locale] = locale.to_s
    end

    redirect_back(fallback_location: root_path)
  end
end

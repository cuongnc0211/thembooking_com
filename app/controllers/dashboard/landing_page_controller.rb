module Dashboard
  class LandingPageController < BaseController
    before_action :set_business

    def edit
    end

    def update
      # Merge landing_page_config toggles into existing JSONB to avoid wiping other keys
      merged_config = (@business.landing_page_config || {}).merge(landing_page_config_params)
      attrs = business_landing_params.merge(landing_page_config: merged_config)

      if @business.update(attrs)
        redirect_to edit_dashboard_business_landing_page_path, notice: "Landing page updated successfully!"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_business
      @business = current_user.business
      redirect_to dashboard_onboarding_path if @business.nil?
    end

    def business_landing_params
      params.require(:business).permit(:slug, :headline, :description, :theme_color, :cover_photo)
    end

    def landing_page_config_params
      raw = params.fetch(:landing_page_config, {}).permit(
        :show_services, :show_gallery, :show_hours, :show_contact, :custom_cta_text
      ).to_h

      # Coerce checkbox strings ("1"/"0") to booleans; leave other values (e.g. CTA text) as-is
      raw.transform_values do |v|
        case v
        when "1", "true"  then true
        when "0", "false" then false
        else v
        end
      end
    end
  end
end

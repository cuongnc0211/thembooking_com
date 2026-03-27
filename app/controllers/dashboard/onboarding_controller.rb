module Dashboard
  class OnboardingController < BaseController
    before_action :redirect_if_completed
    before_action :set_step
    before_action :validate_step_access

    STEPS = [
      { number: 1, name: :user_info, title: "Your Information" },
      { number: 2, name: :business, title: "Your Business" },
      { number: 3, name: :hours, title: "Operating Hours" },
      { number: 4, name: :services, title: "Your Services" }
    ].freeze

    def show
      @step_config = STEPS.find { |s| s[:number] == @step }
      prepare_step_data
    end

    def update
      if process_step
        if @step == 4
          current_user.advance_onboarding!
          redirect_to dashboard_root_path, notice: "Setup complete! Your booking page is ready.", status: :see_other
        else
          advance_to_next_step
        end
      else
        @step_config = STEPS.find { |s| s[:number] == @step }
        prepare_step_data
        render :show, status: :unprocessable_entity
      end
    end

    private

    def redirect_if_completed
      redirect_to dashboard_root_path, status: :see_other if current_user.onboarding_completed?
    end

    def set_step
      @step = if params[:step].present? || params[:current_step].present?
        (params[:step] || params[:current_step]).to_i.clamp(1, 4)
      else
        current_user.onboarding_step.clamp(1, 4)
      end
    end

    def validate_step_access
      unless current_user.can_access_step?(@step)
        redirect_to dashboard_onboarding_path,
          alert: "Complete previous steps first.",
          status: :see_other
      end
    end

    def prepare_step_data
      case @step
      when 1
        @user = current_user
      when 2
        @business = current_user.business || current_user.build_business
      when 3
        @business = current_user.business || current_user.build_business
        @branch = @business.branches.first
        @operating_hours = build_simplified_hours(@branch&.operating_hours)
      when 4
        @business = current_user.business || current_user.build_business
        @branch = @business.branches.first
        @services = @branch&.services&.any? ? @branch.services : [ Service.new ]
      end
    end

    def process_step
      case @step
      when 1 then process_user_info
      when 2 then process_business
      when 3 then process_hours
      when 4 then process_services
      end
    end

    def process_user_info
      if current_user.update(user_params)
        # Validate that required fields are present
        if current_user.name.blank? || current_user.phone.blank?
          current_user.errors.add(:base, "Name and phone are required")
          return false
        end
        true
      else
        false
      end
    end

    def process_business
      business = current_user.business || current_user.build_business
      if business.update(business_brand_params)
        # Create default branch with location data if none exists
        unless business.branches.exists?
          branch_attrs = {
            name: params.dig(:business, :branch_name).presence || "Main Branch",
            slug: params.dig(:business, :slug),
            phone: params.dig(:business, :phone),
            address: params.dig(:business, :address),
            capacity: params.dig(:business, :capacity).presence || 1,
            is_main: true,
            inherit_from_main: false
          }.compact
          business.branches.create!(branch_attrs)
        end
        true
      else
        false
      end
    end

    def process_hours
      hours = expand_simplified_hours(hours_params)
      return false if hours.nil?

      branch = current_user.business&.branches&.first
      return false unless branch

      branch.update(operating_hours: hours)
    end

    def process_services
      branch = current_user.business&.branches&.first
      return false unless branch

      raw_attrs = business_services_params[:services_attributes]
      return true if raw_attrs.blank?

      raw_attrs.each_value do |attrs|
        next if attrs[:_destroy] == "1"
        processed = process_price_cents(attrs)
        branch.services.find_or_initialize_by(name: attrs[:name]).tap do |s|
          s.assign_attributes(processed.except(:_destroy, :id, :price))
          unless s.save
            Rails.logger.warn "Failed to save service during onboarding: #{s.errors.full_messages}"
          end
        end
      end
      true
    end

    def advance_to_next_step
      # Only advance if currently on this step (not editing previous steps)
      if current_user.onboarding_step == @step
        current_user.advance_onboarding!
      end
      redirect_to dashboard_onboarding_path(step: @step + 1), status: :see_other
    end

    # Params methods
    def user_params
      params.require(:user).permit(:name, :phone, :avatar)
    end

    def business_brand_params
      params.require(:business).permit(:name, :business_type, :description, :logo)
    end

    def business_services_params
      params.require(:business).permit(
        services_attributes: [ :id, :name, :duration_minutes, :price, :_destroy ]
      )
    end

    def hours_params
      params.require(:operating_hours).permit(
        weekdays: [ :enabled, :open, :close ],
        saturday: [ :enabled, :open, :close ],
        sunday: [ :enabled, :open, :close ]
      )
    end

    # Convert price from VND to price_cents
    # Note: VND has no subunits, so 1 VND = 1 cent
    def process_price_cents(service_params)
      return service_params unless service_params[:price].present?

      price_in_vnd = service_params[:price].to_s.delete(",").to_i
      service_params.merge(price_cents: price_in_vnd).tap do |params|
        params.delete(:price)
      end
    end

    # Simplified hours helpers
    def build_simplified_hours(operating_hours)
      return default_simplified_hours if operating_hours.blank?

      {
        weekdays: {
          enabled: !operating_hours["monday"]&.dig("closed"),
          open: operating_hours["monday"]&.dig("open") || "09:00",
          close: operating_hours["monday"]&.dig("close") || "19:00"
        },
        saturday: {
          enabled: !operating_hours["saturday"]&.dig("closed"),
          open: operating_hours["saturday"]&.dig("open") || "09:00",
          close: operating_hours["saturday"]&.dig("close") || "17:00"
        },
        sunday: {
          enabled: !operating_hours["sunday"]&.dig("closed"),
          open: operating_hours["sunday"]&.dig("open") || "09:00",
          close: operating_hours["sunday"]&.dig("close") || "17:00"
        }
      }
    end

    def default_simplified_hours
      {
        weekdays: { enabled: true, open: "09:00", close: "19:00" },
        saturday: { enabled: true, open: "09:00", close: "17:00" },
        sunday: { enabled: false, open: "09:00", close: "17:00" }
      }
    end

    def expand_simplified_hours(simplified)
      # Handle both string and symbol keys
      weekdays = simplified[:weekdays]
      saturday = simplified[:saturday]
      sunday = simplified[:sunday]

      # Check if enabled - handle "1", "true", true, or 1
      weekdays_enabled = weekdays && [ true, "true", "1", 1 ].include?(weekdays[:enabled])
      saturday_enabled = saturday && [ true, "true", "1", 1 ].include?(saturday[:enabled])
      sunday_enabled = sunday && [ true, "true", "1", 1 ].include?(sunday[:enabled])

      # At least one day must be enabled
      unless weekdays_enabled || saturday_enabled || sunday_enabled
        return nil
      end

      hours = {}
      %w[monday tuesday wednesday thursday friday].each do |day|
        hours[day] = if weekdays_enabled
          { "open" => weekdays[:open] || weekdays["open"] || "09:00", "close" => weekdays[:close] || weekdays["close"] || "19:00", "closed" => false, "breaks" => [] }
        else
          { "open" => nil, "close" => nil, "closed" => true, "breaks" => [] }
        end
      end

      hours["saturday"] = if saturday_enabled
        { "open" => saturday[:open] || saturday["open"] || "09:00", "close" => saturday[:close] || saturday["close"] || "17:00", "closed" => false, "breaks" => [] }
      else
        { "open" => nil, "close" => nil, "closed" => true, "breaks" => [] }
      end

      hours["sunday"] = if sunday_enabled
        { "open" => sunday[:open] || sunday["open"] || "09:00", "close" => sunday[:close] || sunday["close"] || "17:00", "closed" => false, "breaks" => [] }
      else
        { "open" => nil, "close" => nil, "closed" => true, "breaks" => [] }
      end

      hours
    end
  end
end

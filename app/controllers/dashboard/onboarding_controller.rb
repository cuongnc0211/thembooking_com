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
          complete_onboarding
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
      redirect_to dashboard_root_path if current_user.onboarding_completed?
    end

    def set_step
      @step = if params[:step].present?
        params[:step].to_i.clamp(1, 4)
      else
        current_user.onboarding_step.clamp(1, 4)
      end
    end

    def validate_step_access
      unless current_user.can_access_step?(@step)
        redirect_to dashboard_onboarding_path,
          alert: "Complete previous steps first."
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
        @operating_hours = build_simplified_hours(@business&.operating_hours)
      when 4
        @business = current_user.business || current_user.build_business
        @services = @business.services.any? ? @business.services : [Service.new]
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
      business.assign_attributes(business_params)
      business.save
    end

    def process_hours
      hours = expand_simplified_hours(hours_params)
      return false if hours.nil?

      current_user.business.update(operating_hours: hours)
    end

    def process_services
      services_params_array = params[:services]

      # Return false if no services provided
      return false if services_params_array.nil?
      return false if services_params_array.respond_to?(:empty?) && services_params_array.empty?

      # Handle both array format [{name: ...}] and hash format {0 => {name: ...}}
      services_list = if services_params_array.is_a?(Hash)
        services_params_array.values
      else
        services_params_array.to_a
      end

      return false if services_list.empty?

      # Track if we actually created any services
      created_count = 0

      services_list.each do |service_attrs|
        # Skip if not a hash-like object
        next unless service_attrs.is_a?(Hash) || service_attrs.respond_to?(:to_unsafe_h)

        # Handle both symbol and string keys
        attrs = service_attrs.respond_to?(:to_unsafe_h) ? service_attrs.to_unsafe_h : service_attrs
        service = current_user.business.services.build(
          name: attrs["name"] || attrs[:name],
          duration_minutes: (attrs["duration_minutes"] || attrs[:duration_minutes]).to_i,
          price_cents: ((attrs["price"] || attrs[:price]).to_f * 100).to_i,
          currency: "VND"
        )
        return false unless service.save
        created_count += 1
      end

      # Return false if we didn't create any services
      created_count > 0
    end

    def advance_to_next_step
      current_user.advance_onboarding!
      redirect_to dashboard_onboarding_path
    end

    def complete_onboarding
      current_user.advance_onboarding!
      redirect_to dashboard_root_path, notice: "Setup complete! Your booking page is ready."
    end

    # Params methods
    def user_params
      params.require(:user).permit(:name, :phone, :avatar)
    end

    def business_params
      params.require(:business).permit(
        :name, :business_type, :slug, :phone,
        :capacity, :address, :description, :logo
      )
    end

    def hours_params
      params.require(:operating_hours).permit(
        weekdays: [:enabled, :open, :close],
        saturday: [:enabled, :open, :close],
        sunday: [:enabled, :open, :close]
      )
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
      weekdays = simplified[:weekdays] || simplified["weekdays"]
      saturday = simplified[:saturday] || simplified["saturday"]
      sunday = simplified[:sunday] || simplified["sunday"]

      # Check if enabled - handle "1", "true", true, or 1
      weekdays_enabled = [true, "true", "1", 1].include?(weekdays[:enabled]) || [true, "true", "1", 1].include?(weekdays["enabled"])
      saturday_enabled = [true, "true", "1", 1].include?(saturday[:enabled]) || [true, "true", "1", 1].include?(saturday["enabled"])
      sunday_enabled = [true, "true", "1", 1].include?(sunday[:enabled]) || [true, "true", "1", 1].include?(sunday["enabled"])

      # At least one day must be enabled
      unless weekdays_enabled || saturday_enabled || sunday_enabled
        current_user.business.errors.add(:operating_hours, "must have at least one day open")
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

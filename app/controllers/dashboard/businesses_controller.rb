module Dashboard
  class BusinessesController < BaseController
    before_action :set_business, only: [ :show, :edit, :update ]

    def show
      redirect_to dashboard_onboarding_path if @business.nil?
    end

    def edit
      redirect_to dashboard_onboarding_path if @business.nil?
    end

    def update
      if @business.update(business_params)
        redirect_to dashboard_business_path, notice: "Business updated successfully!"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    # Note: new and create actions removed since business creation now happens through onboarding

    private

    def set_business
      @business = current_user.business
    end

    def business_params
      permitted = params.require(:business).permit(
        :name,
        :slug,
        :business_type,
        :description,
        :address,
        :phone,
        :capacity,
        :logo,
        operating_hours: {
          monday: [ :open, :close, :closed, breaks: [ :start, :end ] ],
          tuesday: [ :open, :close, :closed, breaks: [ :start, :end ] ],
          wednesday: [ :open, :close, :closed, breaks: [ :start, :end ] ],
          thursday: [ :open, :close, :closed, breaks: [ :start, :end ] ],
          friday: [ :open, :close, :closed, breaks: [ :start, :end ] ],
          saturday: [ :open, :close, :closed, breaks: [ :start, :end ] ],
          sunday: [ :open, :close, :closed, breaks: [ :start, :end ] ]
        }
      )

      # Convert operating hours params to proper types
      if permitted[:operating_hours].present?
        permitted[:operating_hours] = normalize_operating_hours(permitted[:operating_hours])
      end

      permitted
    end

    def normalize_operating_hours(hours_params)
      hours_params.to_h.transform_values do |day_params|
        {
          "open" => day_params[:open].presence,
          "close" => day_params[:close].presence,
          "closed" => ActiveModel::Type::Boolean.new.cast(day_params[:closed]),
          "breaks" => (day_params[:breaks] || []).map do |break_params|
            {
              "start" => break_params[:start].presence,
              "end" => break_params[:end].presence
            }.compact
          end.compact
        }
      end
    end
  end
end

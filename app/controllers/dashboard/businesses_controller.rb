module Dashboard
  class BusinessesController < BaseController
    before_action :set_business, only: [ :show, :edit, :update ]
    before_action :redirect_if_has_business, only: [ :new, :create ]
    before_action :redirect_if_no_business, only: [ :show, :edit, :update ]

    def new
      @business = Business.new
    end

    def create
      @business = current_user.build_business(business_params)

      if @business.save
        redirect_to dashboard_business_path, notice: "Business created successfully!"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def show
    end

    def edit
    end

    def update
      if @business.update(business_params)
        redirect_to dashboard_business_path, notice: "Business updated successfully!"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_business
      @business = current_user.business
    end

    def redirect_if_has_business
      redirect_to edit_dashboard_business_path if current_user.business.present?
    end

    def redirect_if_no_business
      redirect_to new_dashboard_business_path if current_user.business.nil?
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

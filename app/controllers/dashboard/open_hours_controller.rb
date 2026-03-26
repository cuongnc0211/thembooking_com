module Dashboard
  class OpenHoursController < BaseController
    before_action :set_branch, only: [ :show, :edit, :update ]

    def show; end

    def edit; end

    def update
      if @branch.update(open_hour_params)
        redirect_to dashboard_branch_open_hour_path(@branch), notice: t("controllers.dashboard.open_hours.flash.updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_branch
      business = current_user.business
      return redirect_to(dashboard_onboarding_path, alert: "Please complete business setup first.") unless business

      @branch = business.branches.find(params[:branch_id])
    rescue ActiveRecord::RecordNotFound
      redirect_to dashboard_branches_path, alert: "Branch not found."
    end

    def open_hour_params
      permitted = params.require(:branch).permit(
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

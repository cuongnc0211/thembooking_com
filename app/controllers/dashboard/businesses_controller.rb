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
      params.require(:business).permit(
        :name,
        :slug,
        :business_type,
        :description,
        :address,
        :phone,
        :capacity,
        :logo
      )
    end
  end
end

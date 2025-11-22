module Dashboard
  class BusinessesController < BaseController
    before_action :set_business, only: [:show, :edit, :update]
    before_action :redirect_if_has_business, only: [:new, :create]
    before_action :redirect_if_no_business, only: [:show, :edit, :update]

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
      params.require(:business).permit(
        :name,
        :slug,
        :business_type,
        :description,
        :address,
        :phone,
        :logo
      )
    end
  end
end

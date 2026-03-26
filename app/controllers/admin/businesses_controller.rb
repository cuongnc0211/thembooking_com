module Admin
  class BusinessesController < Admin::BaseController
    before_action :set_business, only: %i[show edit update destroy]

    def index
      @businesses = Business.includes(:user, :branches, :services, :bookings).order(created_at: :desc)
      @businesses = @businesses.where("businesses.name ILIKE :q", q: "%#{params[:q]}%") if params[:q].present?

      @page = [ params.fetch(:page, 1).to_i, 1 ].max
      @per_page = 25
      @total = @businesses.count
      @businesses = @businesses.offset((@page - 1) * @per_page).limit(@per_page)
    end

    def show; end

    def edit; end

    def update
      if @business.update(business_params)
        redirect_to admin_business_path(@business), notice: "Business updated successfully."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @business.destroy
      redirect_to admin_businesses_path, notice: "Business deleted."
    end

    private

    def set_business
      @business = Business.find(params[:id])
    end

    def business_params
      params.require(:business).permit(:name, :description, :business_type, :currency)
    end
  end
end

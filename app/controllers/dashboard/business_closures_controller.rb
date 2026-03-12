module Dashboard
  class BusinessClosuresController < BaseController
    def index
      @closures = current_user.business.business_closures.upcoming
      @closure = BusinessClosure.new
    end

    def create
      @closure = current_user.business.business_closures.new(closure_params)
      if @closure.save
        redirect_to dashboard_business_closures_path, notice: t("views.dashboard.business_closures.flash.created")
      else
        @closures = current_user.business.business_closures.upcoming
        render :index, status: :unprocessable_entity
      end
    end

    def destroy
      closure = current_user.business.business_closures.find(params[:id])
      closure.destroy!
      redirect_to dashboard_business_closures_path, notice: t("views.dashboard.business_closures.flash.removed")
    end

    private

    def closure_params
      params.require(:business_closure).permit(:date, :reason)
    end
  end
end

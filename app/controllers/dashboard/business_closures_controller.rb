module Dashboard
  class BusinessClosuresController < BaseController
    before_action :set_branch

    def index
      @closures = @branch.business_closures.upcoming
      @closure = BusinessClosure.new
    end

    def create
      @closure = @branch.business_closures.new(closure_params)
      if @closure.save
        redirect_to dashboard_branch_business_closures_path(@branch), notice: t("views.dashboard.business_closures.flash.created")
      else
        @closures = @branch.business_closures.upcoming
        render :index, status: :unprocessable_entity
      end
    end

    def destroy
      closure = @branch.business_closures.find(params[:id])
      closure.destroy!
      redirect_to dashboard_branch_business_closures_path(@branch), notice: t("views.dashboard.business_closures.flash.removed")
    end

    private

    def set_branch
      business = current_user.business
      return redirect_to(dashboard_onboarding_path, alert: "Please complete business setup first.") unless business

      @branch = business.branches.find(params[:branch_id])
    rescue ActiveRecord::RecordNotFound
      redirect_to dashboard_branches_path, alert: "Branch not found."
    end

    def closure_params
      params.require(:business_closure).permit(:date, :reason)
    end
  end
end

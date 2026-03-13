module Dashboard
  class BranchesController < BaseController
    before_action :set_business
    before_action :set_branch, only: [ :show, :edit, :update, :destroy ]

    def index
      @branches = @business.branches.order(:position, :name)
    end

    def show; end

    def new
      @branch = @business.branches.build
    end

    def create
      @branch = @business.branches.build(branch_params)
      if @branch.save
        redirect_to dashboard_branch_path(@branch), notice: "Branch created successfully."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @branch.update(branch_params)
        redirect_to dashboard_branch_path(@branch), notice: "Branch updated successfully."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @branch.active? && @business.branches.where(active: true).count <= 1
        redirect_to dashboard_branches_path, alert: "Cannot deactivate the last active branch."
        return
      end
      @branch.update!(active: !@branch.active)
      redirect_to dashboard_branches_path, notice: "Branch #{@branch.active? ? 'activated' : 'deactivated'}."
    end

    private

    def set_business
      @business = current_user.business
      unless @business
        redirect_to dashboard_onboarding_path, alert: "Please complete business setup first."
      end
    end

    def set_branch
      @branch = @business.branches.find(params[:id])
    end

    def branch_params
      params.require(:branch).permit(:name, :slug, :address, :phone, :capacity)
    end
  end
end

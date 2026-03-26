module Dashboard
  class ServicesController < BaseController
    before_action :set_branch
    before_action :set_service, only: [ :edit, :update, :destroy, :move_up, :move_down ]

    def index
      @services = @branch.services.order(:position)
    end

    def new
      @service = @branch.services.build
    end

    def create
      @service = @branch.services.build(service_params)

      # Set position to next available number
      max_position = @branch.services.maximum(:position) || 0
      @service.position = max_position + 1

      if @service.save
        redirect_to dashboard_branch_services_path(@branch), notice: "Service created successfully."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @service.update(service_params)
        redirect_to dashboard_branch_services_path(@branch), notice: "Service updated successfully."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @service.destroy
      redirect_to dashboard_branch_services_path(@branch), notice: "Service deleted successfully."
    end

    def move_up
      # Find the service immediately above (lower position number)
      previous_service = @branch.services
                                .where("position < ?", @service.position)
                                .order(position: :desc)
                                .first

      if previous_service
        # Swap positions
        @service.position, previous_service.position = previous_service.position, @service.position
        @service.save
        previous_service.save
      end

      redirect_to dashboard_branch_services_path(@branch)
    end

    def move_down
      # Find the service immediately below (higher position number)
      next_service = @branch.services
                            .where("position > ?", @service.position)
                            .order(position: :asc)
                            .first

      if next_service
        # Swap positions
        @service.position, next_service.position = next_service.position, @service.position
        @service.save
        next_service.save
      end

      redirect_to dashboard_branch_services_path(@branch)
    end

    private

    def set_branch
      business = current_user.business
      return redirect_to(dashboard_onboarding_path, alert: "Please complete business setup first.") unless business

      @branch = business.branches.find(params[:branch_id])
    rescue ActiveRecord::RecordNotFound
      redirect_to dashboard_branches_path, alert: "Branch not found."
    end

    def set_service
      @service = @branch.services.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      head :not_found
    end

    def service_params
      params.require(:service).permit(:name, :description, :duration_minutes, :price, :active, :service_category_id)
    end
  end
end

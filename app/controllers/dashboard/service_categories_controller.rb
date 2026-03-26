module Dashboard
  class ServiceCategoriesController < BaseController
    before_action :set_branch
    before_action :set_category, only: [ :edit, :update, :destroy ]

    def index
      @categories = @branch.service_categories.ordered
    end

    def new
      @category = @branch.service_categories.build
      @assignable_services = unassigned_services
    end

    def create
      @category = @branch.service_categories.build(category_params)
      max_position = @branch.service_categories.maximum(:position) || 0
      @category.position = max_position + 1

      respond_to do |format|
        if @category.save
          assign_services_to_category
          format.html { redirect_to dashboard_branch_service_categories_path(@branch), notice: "Category created successfully." }
          format.json { render json: { id: @category.id, name: @category.name }, status: :created }
        else
          format.html do
            @assignable_services = unassigned_services
            render :new, status: :unprocessable_entity
          end
          format.json { render json: { errors: @category.errors.full_messages }, status: :unprocessable_entity }
        end
      end
    end

    def edit
      @assignable_services = unassigned_services_for_edit
    end

    def update
      if @category.update(category_params)
        assign_services_to_category
        redirect_to dashboard_branch_service_categories_path(@branch), notice: "Category updated successfully."
      else
        @assignable_services = unassigned_services_for_edit
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @category.destroy
      redirect_to dashboard_branch_service_categories_path(@branch),
                  notice: "Category deleted. Services have been uncategorized."
    end

    private

    def set_branch
      business = current_user.business
      return redirect_to(dashboard_onboarding_path, alert: "Please complete business setup first.") unless business

      @branch = business.branches.find(params[:branch_id])
    rescue ActiveRecord::RecordNotFound
      redirect_to dashboard_branches_path, alert: "Branch not found."
    end

    def set_category
      @category = @branch.service_categories.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      head :not_found
    end

    def category_params
      params.require(:service_category).permit(:name)
    end

    # Services in this branch with no category assigned
    def unassigned_services
      @branch.services.where(service_category_id: nil).order(:position)
    end

    # For edit: services with no category OR already in this category
    def unassigned_services_for_edit
      @branch.services
             .where(service_category_id: [ nil, @category.id ])
             .order(:position)
    end

    # Assign selected service IDs to category; clear any deselected ones
    def assign_services_to_category
      selected_ids = Array(params.dig(:service_category, :service_ids)).map(&:to_i).reject(&:zero?)

      @branch.services.where(id: selected_ids).update_all(service_category_id: @category.id)

      @branch.services
             .where(service_category_id: @category.id)
             .where.not(id: selected_ids)
             .update_all(service_category_id: nil)
    end
  end
end

module Admin
  class StaffsController < Admin::BaseController
    before_action :require_super_admin!
    before_action :set_staff, only: %i[show edit update destroy]

    def index
      @staffs = Staff.order(created_at: :desc)
      @staffs = @staffs.where("name ILIKE :q OR email_address ILIKE :q", q: "%#{params[:q]}%") if params[:q].present?
      @page = [ params.fetch(:page, 1).to_i, 1 ].max
      @per_page = 25
      @total = @staffs.count
      @staffs = @staffs.offset((@page - 1) * @per_page).limit(@per_page)
    end

    def show; end

    def new
      @staff = Staff.new
    end

    def edit; end

    def create
      @staff = Staff.new(staff_params)
      if @staff.save
        redirect_to admin_staff_path(@staff), notice: "Staff created successfully."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      p = staff_params
      p = p.except(:password, :password_confirmation) if p[:password].blank?
      if @staff.update(p)
        redirect_to admin_staff_path(@staff), notice: "Staff updated successfully."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @staff == current_staff
        redirect_to admin_staffs_path, alert: "You cannot delete your own account."
      else
        @staff.destroy
        redirect_to admin_staffs_path, notice: "Staff deleted."
      end
    end

    private

    def set_staff
      @staff = Staff.find(params[:id])
    end

    def staff_params
      params.require(:staff).permit(:name, :email_address, :role, :active, :password, :password_confirmation)
    end

  end
end

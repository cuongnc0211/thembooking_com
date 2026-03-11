module Admin
  class UsersController < Admin::BaseController
    before_action :set_user, only: %i[show edit update destroy]

    def index
      @users = User.includes(:business).order(created_at: :desc)
      @users = @users.where("name ILIKE :q OR email_address ILIKE :q", q: "%#{params[:q]}%") if params[:q].present?

      @page = [ params.fetch(:page, 1).to_i, 1 ].max
      @per_page = 25
      @total = @users.count
      @users = @users.offset((@page - 1) * @per_page).limit(@per_page)
    end

    def show; end

    def edit; end

    def update
      if @user.update(user_params)
        redirect_to admin_user_path(@user), notice: "User updated successfully."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @user.destroy
      redirect_to admin_users_path, notice: "User deleted."
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(:name, :email_address, :phone, :time_zone, :onboarding_completed_at)
    end
  end
end

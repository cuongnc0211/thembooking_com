class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]
  redirect_authenticated_user only: %i[new create]

  def new
    @user = User.new
  end

  def create
    @user = User.new(registration_params)

    # Set timezone from browser detection or cookie
    @user.time_zone = params[:detected_timezone].presence || cookies[:browser_timezone] || 'UTC'

    if @user.save
      redirect_to root_path, notice: "Please check your email to confirm your account."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def registration_params
    params.require(:user).permit(:email_address, :password, :password_confirmation)
  end
end

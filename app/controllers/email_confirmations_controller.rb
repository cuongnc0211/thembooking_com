class EmailConfirmationsController < ApplicationController
  allow_unauthenticated_access

  def show
    user = User.find_by(email_confirmation_token: params[:token])

    if user.nil?
      redirect_to root_path, alert: "Invalid confirmation token."
    elsif user.confirmed?
      redirect_to new_session_path, notice: "Your email is already confirmed. Please log in."
    elsif user.confirmation_token_expired?
      redirect_to root_path, alert: "Confirmation token has expired. Please request a new one."
    else
      user.confirm!
      redirect_to new_session_path, notice: "Your email has been confirmed! You can now log in."
    end
  end

  def resend
    user = User.find_by(email_address: params[:email])

    if user && !user.confirmed?
      user.send_confirmation_instructions
      redirect_to root_path, notice: "Confirmation email has been resent. Please check your inbox."
    else
      redirect_to root_path, alert: "Unable to resend confirmation email."
    end
  end
end

class UserMailer < ApplicationMailer
  def confirmation_instructions(user)
    @user = user
    @confirmation_url = confirm_email_url(token: @user.email_confirmation_token)

    mail(to: @user.email_address, subject: "Please confirm your ThemBooking account")
  end

  def welcome_email
    @user = params[:user]
    @login_url = new_session_url # or any URL you want

    mail(
      to: @user.email_address,
      subject: "Welcome to ThemBooking.com!"
    )
  end
end

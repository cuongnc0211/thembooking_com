class UserMailer < ApplicationMailer
  def confirmation_instructions(user)
    @user = user
    @confirmation_url = confirm_email_url(token: @user.email_confirmation_token)

    mail(to: @user.email_address, subject: "Please confirm your Bukmeup account")
  end
end

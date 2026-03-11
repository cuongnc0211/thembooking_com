module Admin
  class SessionsController < Admin::BaseController
    allow_unauthenticated_admin_access only: %i[new create]
    rate_limit to: 10, within: 3.minutes, only: :create,
              with: -> { redirect_to admin_sign_in_path, alert: "Too many attempts. Try again later." }

    layout "admin_login"

    def new
    end

    def create
      staff = Staff.authenticate_by(
        email_address: params[:email_address],
        password: params[:password]
      )

      if staff&.active?
        start_admin_session_for(staff)
        redirect_to after_admin_authentication_url, notice: "Signed in successfully."
      else
        redirect_to admin_sign_in_path, alert: "Invalid email or password."
      end
    end

    def destroy
      terminate_admin_session
      redirect_to admin_sign_in_path, status: :see_other
    end
  end
end

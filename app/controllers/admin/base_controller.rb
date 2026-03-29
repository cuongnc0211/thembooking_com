module Admin
  class BaseController < ApplicationController
    # Skip user authentication (inherited from ApplicationController via Authentication concern)
    skip_before_action :require_authentication

    # Use admin-specific authentication (staff session via admin_session_id cookie)
    include AdminAuthentication

    layout "admin"

    private

    def require_super_admin!
      redirect_to admin_root_path, alert: "Access denied." unless current_staff&.super_admin?
    end
  end
end

module Admin
  class BaseController < ApplicationController
    # Skip user authentication (inherited from ApplicationController via Authentication concern)
    skip_before_action :require_authentication

    # Use admin-specific authentication (staff session via admin_session_id cookie)
    include AdminAuthentication

    layout "admin"
  end
end

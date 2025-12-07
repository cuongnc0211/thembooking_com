module Dashboard
  class BaseController < ApplicationController
    # All controllers in Dashboard namespace require authentication
    # (inherited from ApplicationController's require_authentication before_action)

    layout "dashboard"

    # Require onboarding completion before accessing dashboard
    before_action :require_onboarding_complete

    private

    def require_onboarding_complete
      # Skip for OnboardingController (it handles its own access control)
      return if skip_onboarding_check?

      unless current_user.onboarding_completed?
        redirect_to dashboard_onboarding_path
      end
    end

    def skip_onboarding_check?
      # OnboardingController manages its own access control
      is_a?(OnboardingController)
    end
  end
end

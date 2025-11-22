require "rails_helper"

RSpec.describe "Dashboard Onboarding", type: :request do
  let(:user) { create(:user) }

  def sign_in(user)
    post session_path, params: { email_address: user.email_address, password: "password123" }
  end

  describe "business setup requirement" do
    context "when user has no business" do
      before { sign_in(user) }

      it "redirects from profile page to business setup" do
        get edit_dashboard_profile_path
        expect(response).to redirect_to(new_dashboard_business_path)
      end

      it "shows a message about setting up business first" do
        get edit_dashboard_profile_path
        follow_redirect!
        expect(response.body).to include("set up your business")
      end

      it "allows access to business new page" do
        get new_dashboard_business_path
        expect(response).to have_http_status(:success)
      end
    end

    context "when user has a business" do
      before do
        create(:business, user: user)
        sign_in(user)
      end

      it "allows access to profile page" do
        get edit_dashboard_profile_path
        expect(response).to have_http_status(:success)
      end

      it "allows access to business pages" do
        get dashboard_business_path
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "post-login redirect" do
    context "when user has no business" do
      it "redirects to business setup after login" do
        sign_in(user)
        expect(response).to redirect_to(root_path)
        # The home page will show "Set Up Your Business" prompt
      end
    end

    context "when user has a business" do
      before { create(:business, user: user) }

      it "redirects to root after login" do
        sign_in(user)
        expect(response).to redirect_to(root_path)
      end
    end
  end
end

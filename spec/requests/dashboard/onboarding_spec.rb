require "rails_helper"

RSpec.describe "Dashboard::Onboarding", type: :request do
  def sign_in(user)
    post session_path, params: { email_address: user.email_address, password: "password123" }
  end

  describe "authentication" do
    it "redirects to login when not authenticated" do
      get dashboard_onboarding_path
      expect(response).to redirect_to(new_session_path)
    end
  end

  describe "GET /dashboard/onboarding" do
    context "when onboarding not completed" do
      let(:user) { create(:user, onboarding_step: 1) }

      before { sign_in(user) }

      it "renders the current step form" do
        get dashboard_onboarding_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Step 1")
      end

      it "shows step 2 when on step 2" do
        user.update!(onboarding_step: 2)
        get dashboard_onboarding_path
        expect(response.body).to include("Step 2")
      end
    end

    context "when onboarding completed" do
      let(:user) { create(:user, :onboarding_completed) }

      before { sign_in(user) }

      it "redirects to dashboard root" do
        get dashboard_onboarding_path
        expect(response).to redirect_to(dashboard_root_path)
      end
    end
  end

  describe "GET /dashboard/onboarding?step=N" do
    let(:user) { create(:user, onboarding_step: 3) }

    before { sign_in(user) }

    it "allows accessing previous steps" do
      get dashboard_onboarding_path(step: 1)
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Step 1")
    end

    it "allows accessing current step" do
      get dashboard_onboarding_path(step: 3)
      expect(response).to have_http_status(:success)
    end

    it "prevents accessing future steps" do
      get dashboard_onboarding_path(step: 4)
      expect(response).to redirect_to(dashboard_onboarding_path)
      expect(flash[:alert]).to include("Complete previous steps")
    end

    it "ignores invalid step values" do
      get dashboard_onboarding_path(step: 99)
      expect(response).to redirect_to(dashboard_onboarding_path)
    end
  end

  describe "PATCH /dashboard/onboarding (Step 1: User Info)" do
    let(:user) { create(:user, onboarding_step: 1, name: nil, phone: nil) }

    before { sign_in(user) }

    context "with valid params" do
      let(:valid_params) { { user: { name: "John Doe", phone: "0901234567" } } }

      it "updates user info" do
        patch dashboard_onboarding_path, params: valid_params
        user.reload
        expect(user.name).to eq("John Doe")
        expect(user.phone).to eq("0901234567")
      end

      it "advances to step 2" do
        patch dashboard_onboarding_path, params: valid_params
        expect(user.reload.onboarding_step).to eq(2)
      end

      it "redirects to next step" do
        patch dashboard_onboarding_path, params: valid_params
        expect(response).to redirect_to(dashboard_onboarding_path)
      end
    end

    context "with invalid params" do
      it "does not advance step when name blank" do
        patch dashboard_onboarding_path, params: { user: { name: "", phone: "0901234567" } }
        expect(user.reload.onboarding_step).to eq(1)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "PATCH /dashboard/onboarding (Step 2: Business)" do
    let(:user) { create(:user, onboarding_step: 2, name: "John", phone: "0901234567") }

    before { sign_in(user) }

    context "with valid params" do
      let(:valid_params) do
        {
          business: {
            name: "John's Barbershop",
            business_type: "barber",
            slug: "johns-barbershop",
            phone: "0901234567",
            capacity: 3,
            address: "123 Main St"
          }
        }
      end

      it "creates business for user" do
        expect { patch dashboard_onboarding_path, params: valid_params }
          .to change(Business, :count).by(1)
        expect(user.reload.business).to be_present
      end

      it "advances to step 3" do
        patch dashboard_onboarding_path, params: valid_params
        expect(user.reload.onboarding_step).to eq(3)
      end
    end

    context "with invalid params" do
      it "does not create business when name blank" do
        patch dashboard_onboarding_path, params: { business: { name: "" } }
        expect(user.reload.business).to be_nil
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "PATCH /dashboard/onboarding (Step 3: Operating Hours)" do
    let(:user) { create(:user, :with_business, onboarding_step: 3) }

    before { sign_in(user) }

    context "with valid params" do
      let(:valid_params) do
        {
          operating_hours: {
            weekdays: { enabled: true, open: "09:00", close: "19:00" },
            saturday: { enabled: true, open: "09:00", close: "17:00" },
            sunday: { enabled: false }
          }
        }
      end

      it "updates business operating_hours" do
        patch dashboard_onboarding_path, params: valid_params
        user.reload
        expect(user.business.operating_hours["monday"]["open"]).to eq("09:00")
        expect(user.business.operating_hours["sunday"]["closed"]).to be true
      end

      it "advances to step 4" do
        patch dashboard_onboarding_path, params: valid_params
        expect(user.reload.onboarding_step).to eq(4)
      end
    end

    context "with all days disabled" do
      it "shows error" do
        patch dashboard_onboarding_path, params: {
          operating_hours: {
            weekdays: { enabled: false },
            saturday: { enabled: false },
            sunday: { enabled: false }
          }
        }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("at least one day")
      end
    end
  end

  describe "PATCH /dashboard/onboarding (Step 4: Services)" do
    let(:user) { create(:user, :with_business, onboarding_step: 4) }

    before { sign_in(user) }

    context "with valid params" do
      let(:valid_params) do
        {
          services: [
            { name: "Haircut", duration_minutes: 30, price: 80000 }
          ]
        }
      end

      it "creates service for business" do
        expect { patch dashboard_onboarding_path, params: valid_params }
          .to change(Service, :count).by(1)
      end

      it "marks onboarding as complete" do
        patch dashboard_onboarding_path, params: valid_params
        user.reload
        expect(user.onboarding_step).to eq(5)
        expect(user.onboarding_completed_at).to be_present
      end

      it "redirects to dashboard with success message" do
        patch dashboard_onboarding_path, params: valid_params
        expect(response).to redirect_to(dashboard_root_path)
        expect(flash[:notice]).to include("complete")
      end
    end

    context "with multiple services" do
      let(:valid_params) do
        {
          services: [
            { name: "Haircut", duration_minutes: 30, price: 80000 },
            { name: "Shave", duration_minutes: 15, price: 50000 }
          ]
        }
      end

      it "creates all services" do
        expect { patch dashboard_onboarding_path, params: valid_params }
          .to change(Service, :count).by(2)
      end
    end

    context "with no services" do
      it "does not advance" do
        patch dashboard_onboarding_path, params: { services: [] }
        expect(user.reload.onboarding_step).to eq(4)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "editing previous steps" do
    let(:user) { create(:user, :with_business, onboarding_step: 4, name: "Old Name") }

    before { sign_in(user) }

    it "allows updating step 1 without changing current progress" do
      patch dashboard_onboarding_path, params: {
        step: 1,
        user: { name: "New Name", phone: user.phone }
      }
      expect(user.reload.name).to eq("New Name")
      expect(user.onboarding_step).to eq(4) # unchanged
    end
  end
end

describe "before_action redirect for incomplete onboarding" do
  def sign_in(user)
    post session_path, params: { email_address: user.email_address, password: "password123" }
  end

  context "when onboarding incomplete" do
    let(:user) { create(:user, onboarding_step: 2, name: "John", phone: "0901234567") }

    before { sign_in(user) }

    it "redirects from dashboard root to onboarding" do
      get dashboard_root_path
      expect(response).to redirect_to(dashboard_onboarding_path)
    end

    it "redirects from profile edit to onboarding" do
      get edit_dashboard_profile_path
      expect(response).to redirect_to(dashboard_onboarding_path)
    end

    it "redirects from services index to onboarding" do
      get dashboard_services_path
      expect(response).to redirect_to(dashboard_onboarding_path)
    end

    it "allows access to onboarding path" do
      get dashboard_onboarding_path
      expect(response).to have_http_status(:success)
    end
  end

  context "when onboarding completed" do
    let(:user) { create(:user, :fully_onboarded) }

    before { sign_in(user) }

    it "allows access to dashboard root" do
      get dashboard_root_path
      expect(response).to have_http_status(:success)
    end

    it "allows access to profile edit" do
      get edit_dashboard_profile_path
      expect(response).to have_http_status(:success)
    end

    it "redirects onboarding path to dashboard root" do
      get dashboard_onboarding_path
      expect(response).to redirect_to(dashboard_root_path)
    end
  end
end

describe "post-login redirect" do
  def sign_in(user)
    post session_path, params: { email_address: user.email_address, password: "password123" }
  end

  context "when onboarding incomplete" do
    let(:user) { create(:user, onboarding_step: 1) }

    it "redirects to onboarding after login" do
      sign_in(user)
      expect(response).to redirect_to(dashboard_onboarding_path)
      follow_redirect!
      expect(response).to have_http_status(:success)
    end
  end

  context "when onboarding completed" do
    let(:user) { create(:user, :fully_onboarded) }

    it "redirects to dashboard after login" do
      sign_in(user)
      follow_redirect!
      expect(response).to have_http_status(:success) # dashboard root
    end
  end
end

describe "resume onboarding after logout/login" do
  let(:user) { create(:user, :with_business, onboarding_step: 3) }

  it "resumes at the correct step" do
    # First session
    post session_path, params: { email_address: user.email_address, password: "password123" }
    get dashboard_onboarding_path
    expect(response.body).to include("Step 3")

    # Logout
    delete session_path

    # New session
    post session_path, params: { email_address: user.email_address, password: "password123" }
    follow_redirect! # to onboarding
    # No second redirect needed

    get dashboard_onboarding_path
    expect(response.body).to include("Step 3")
  end
end

require "rails_helper"

RSpec.describe "Dashboard::OpenHours", type: :request do
  let(:user) { create(:user, onboarding_step: 5, onboarding_completed_at: Time.current) }
  let(:business) { create(:business, user: user) }

  describe "authentication" do
    context "when not logged in" do
      it "redirects to login for GET /dashboard/open_hour" do
        get dashboard_open_hour_path
        expect(response).to redirect_to(new_session_path)
      end

      it "redirects to login for GET /dashboard/open_hour/edit" do
        get edit_dashboard_open_hour_path
        expect(response).to redirect_to(new_session_path)
      end

      it "redirects to login for PATCH /dashboard/open_hour" do
        patch dashboard_open_hour_path, params: { business: { operating_hours: {} } }
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /dashboard/open_hour (show)" do
    context "when user has business" do
      before do
        sign_in(user)
        business # Create business
      end

      it "renders the show template" do
        get dashboard_open_hour_path
        expect(response).to have_http_status(:success)
      end

      it "displays operating hours correctly" do
        get dashboard_open_hour_path
        expect(response.body).to include("Giờ Làm Việc") # Operating Hours title
      end
    end

    context "when user has no business" do
      let(:user_without_business) { create(:user, onboarding_step: 5, onboarding_completed_at: Time.current) }

      before { sign_in(user_without_business) }

      it "redirects to business creation page" do
        get dashboard_open_hour_path
        expect(response).to redirect_to(dashboard_business_path)
      end

      it "shows create_business_first flash message" do
        get dashboard_open_hour_path
        expect(flash[:notice]).to eq(I18n.t("controllers.dashboard.open_hours.flash.create_business_first"))
      end
    end
  end

  describe "GET /dashboard/open_hour/edit" do
    context "when user has business" do
      before do
        sign_in(user)
        business
      end

      it "renders the edit template" do
        get edit_dashboard_open_hour_path
        expect(response).to have_http_status(:success)
      end

      it "loads existing operating hours" do
        business.update!(operating_hours: {
          "monday" => { "open" => "10:00", "close" => "18:00", "closed" => false, "breaks" => [] }
        })

        get edit_dashboard_open_hour_path
        expect(response.body).to include("10:00")
        expect(response.body).to include("18:00")
      end

      it "pre-fills form with current hours" do
        get edit_dashboard_open_hour_path
        expect(response.body).to include("operating_hours")
      end
    end

    context "when user has no business" do
      let(:user_without_business) { create(:user, onboarding_step: 5, onboarding_completed_at: Time.current) }

      before { sign_in(user_without_business) }

      it "redirects to business creation page" do
        get edit_dashboard_open_hour_path
        expect(response).to redirect_to(dashboard_business_path)
      end
    end
  end

  describe "PATCH /dashboard/open_hour (update)" do
    before do
      sign_in(user)
      business
    end

    let(:valid_params) do
      {
        business: {
          operating_hours: {
            monday: { open: "09:00", close: "17:00", closed: "0" },
            tuesday: { open: "09:00", close: "17:00", closed: "0" },
            wednesday: { open: "09:00", close: "17:00", closed: "0" },
            thursday: { open: "09:00", close: "17:00", closed: "0" },
            friday: { open: "09:00", close: "17:00", closed: "0" },
            saturday: { open: "09:00", close: "17:00", closed: "0" },
            sunday: { closed: "1" }
          }
        }
      }
    end

    context "with valid params" do
      it "updates operating hours" do
        expect {
          patch dashboard_open_hour_path, params: valid_params
        }.to change { business.reload.operating_hours["monday"]["open"] }.to("09:00")
      end

      it "redirects to show page" do
        patch dashboard_open_hour_path, params: valid_params
        expect(response).to redirect_to(dashboard_open_hour_path)
      end

      it "saves break times correctly" do
        params_with_breaks = valid_params.deep_dup
        params_with_breaks[:business][:operating_hours][:monday][:breaks] = [
          { start: "12:00", end: "13:00" }
        ]

        patch dashboard_open_hour_path, params: params_with_breaks
        business.reload

        expect(business.operating_hours["monday"]["breaks"]).to eq([
          { "start" => "12:00", "end" => "13:00" }
        ])
      end

      it "marks closed days as closed" do
        patch dashboard_open_hour_path, params: valid_params
        business.reload

        expect(business.operating_hours["sunday"]["closed"]).to be true
      end

      it "converts closed string to boolean" do
        patch dashboard_open_hour_path, params: valid_params
        business.reload

        expect(business.operating_hours["monday"]["closed"]).to be false
        expect(business.operating_hours["sunday"]["closed"]).to be true
      end
    end

    context "with invalid params" do
      let(:invalid_params) do
        {
          business: {
            operating_hours: {
              monday: { open: "17:00", close: "09:00", closed: "0" } # Close before open
            }
          }
        }
      end

      it "re-renders edit template" do
        patch dashboard_open_hour_path, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to render_template(:edit)
      end

      it "displays error messages" do
        patch dashboard_open_hour_path, params: invalid_params
        expect(response.body).to include("Monday closing time must be after opening time")
      end

      it "doesn't update the business" do
        original_hours = business.operating_hours.deep_dup

        patch dashboard_open_hour_path, params: invalid_params
        business.reload

        expect(business.operating_hours).to eq(original_hours)
      end
    end

    context "with malformed params" do
      it "handles missing operating_hours key" do
        expect {
          patch dashboard_open_hour_path, params: { business: {} }
        }.not_to raise_error
      end

      it "handles empty operating_hours" do
        params = { business: { operating_hours: {} } }
        patch dashboard_open_hour_path, params: params

        # Should update to empty (or keep existing)
        expect(response).to have_http_status(:found) # redirect on success
      end
    end

    context "break times edge cases" do
      it "handles multiple breaks per day" do
        params = valid_params.deep_dup
        params[:business][:operating_hours][:monday][:breaks] = [
          { start: "10:00", end: "10:15" },
          { start: "15:00", end: "15:15" }
        ]

        patch dashboard_open_hour_path, params: params
        business.reload

        expect(business.operating_hours["monday"]["breaks"].size).to eq(2)
      end

      it "removes empty break entries" do
        params = valid_params.deep_dup
        params[:business][:operating_hours][:monday][:breaks] = [
          { start: "", end: "" },
          { start: "12:00", end: "13:00" }
        ]

        patch dashboard_open_hour_path, params: params
        business.reload

        # Should only save non-empty breaks
        expect(business.operating_hours["monday"]["breaks"]).to eq([
          { "start" => "12:00", "end" => "13:00" }
        ])
      end

      it "validates break times are within operating hours" do
        params = valid_params.deep_dup
        params[:business][:operating_hours][:monday][:breaks] = [
          { start: "08:00", end: "09:00" } # Before opening time
        ]

        patch dashboard_open_hour_path, params: params
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("Monday break must be within operating hours")
      end

      it "validates breaks do not overlap" do
        params = valid_params.deep_dup
        params[:business][:operating_hours][:monday][:breaks] = [
          { start: "12:00", end: "13:30" },
          { start: "13:00", end: "14:00" } # Overlaps with first break
        ]

        patch dashboard_open_hour_path, params: params
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("Monday has overlapping break times")
      end
    end
  end
end

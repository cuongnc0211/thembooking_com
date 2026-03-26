require "rails_helper"

RSpec.describe "Dashboard::Operations", type: :request do
  let(:browser_headers) { { "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" } }
  let(:user)     { create(:user, :onboarding_completed) }
  let(:business) { create(:business, user: user) }
  let!(:branch)  { create(:branch, business: business) }

  before do
    sign_in(user)
    business # ensure exists
  end

  # ---------------------------------------------------------------------------
  # GET /dashboard/branches/:branch_id/operations (HTML shell)
  # ---------------------------------------------------------------------------
  describe "GET /dashboard/branches/:branch_id/operations" do
    it "renders the operations page with React mount point" do
      get dashboard_branch_operations_path(branch), headers: browser_headers
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("react-operations-root")
    end

    it "redirects to sign-in when not authenticated" do
      sign_out
      get dashboard_branch_operations_path(branch), headers: browser_headers
      expect(response).to redirect_to(new_session_path)
    end

    context "when another user's branch" do
      let(:other_branch) { create(:branch) }

      it "redirects to branches list" do
        get dashboard_branch_operations_path(other_branch), headers: browser_headers
        expect(response).to redirect_to(dashboard_branches_path)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # GET /dashboard/branches/:branch_id/operations/data (JSON payload)
  # ---------------------------------------------------------------------------
  describe "GET /dashboard/branches/:branch_id/operations/data" do
    it "returns JSON with all expected top-level keys" do
      get data_dashboard_branch_operations_path(branch),
          headers: browser_headers.merge("Accept" => "application/json")
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.keys).to include("branch", "in_service", "waiting", "today_schedule", "counts")
      expect(json["branch"]).to include("name", "capacity")
      expect(json["counts"].keys).to include("in_service", "waiting", "completed_today", "total_today")
    end

    it "returns in_service bookings for in-progress bookings today" do
      create(:booking, :walk_in, :skip_validations,
             branch: branch, status: :in_progress,
             scheduled_at: Time.current, started_at: Time.current,
             end_time: 1.hour.from_now)

      get data_dashboard_branch_operations_path(branch),
          headers: browser_headers.merge("Accept" => "application/json")
      json = JSON.parse(response.body)

      expect(json["in_service"].length).to eq(1)
      expect(json["counts"]["in_service"]).to eq(1)
    end

    it "returns waiting bookings for confirmed bookings scheduled in the future today" do
      create(:booking, :skip_validations,
             branch: branch, status: :confirmed,
             scheduled_at: 2.hours.from_now,
             end_time: 3.hours.from_now)

      get data_dashboard_branch_operations_path(branch),
          headers: browser_headers.merge("Accept" => "application/json")
      json = JSON.parse(response.body)

      expect(json["waiting"].length).to eq(1)
    end

    it "excludes bookings not scheduled for today" do
      create(:booking, branch: branch, status: :confirmed,
             scheduled_at: 1.day.from_now)

      get data_dashboard_branch_operations_path(branch),
          headers: browser_headers.merge("Accept" => "application/json")
      json = JSON.parse(response.body)

      expect(json["today_schedule"]).to be_empty
    end

    it "excludes cancelled and no_show bookings" do
      create(:booking, :skip_validations,
             branch: branch, status: :cancelled,
             scheduled_at: Time.current, end_time: 1.hour.from_now)

      get data_dashboard_branch_operations_path(branch),
          headers: browser_headers.merge("Accept" => "application/json")
      json = JSON.parse(response.body)

      expect(json["today_schedule"]).to be_empty
    end

    it "includes serialized services for each booking" do
      create(:booking, :walk_in, :skip_validations,
             branch: branch, status: :in_progress,
             scheduled_at: Time.current, started_at: Time.current,
             end_time: 1.hour.from_now)

      get data_dashboard_branch_operations_path(branch),
          headers: browser_headers.merge("Accept" => "application/json")
      json = JSON.parse(response.body)

      first = json["in_service"].first
      expect(first).to have_key("services")
      expect(first["services"]).to be_an(Array)
      expect(first["services"].first).to include("id", "name", "duration_minutes")
    end

    it "computes elapsed_minutes for in-progress bookings" do
      create(:booking, :walk_in, :skip_validations,
             branch: branch, status: :in_progress,
             scheduled_at: 30.minutes.ago, started_at: 30.minutes.ago,
             end_time: 1.hour.from_now)

      get data_dashboard_branch_operations_path(branch),
          headers: browser_headers.merge("Accept" => "application/json")
      json = JSON.parse(response.body)

      elapsed = json["in_service"].first["elapsed_minutes"]
      expect(elapsed).to be_within(2).of(30)
    end

    it "redirects when accessing another user's branch" do
      other_branch = create(:branch)
      get data_dashboard_branch_operations_path(other_branch),
          headers: browser_headers.merge("Accept" => "application/json")
      expect(response).to redirect_to(dashboard_branches_path)
    end
  end

  # ---------------------------------------------------------------------------
  # GET /dashboard/branches/:branch_id/operations/services_list
  # ---------------------------------------------------------------------------
  describe "GET /dashboard/branches/:branch_id/operations/services_list" do
    it "returns only active services as JSON array" do
      create(:service, branch: branch, name: "Haircut", active: true)
      create(:service, branch: branch, name: "Inactive Svc", active: false)

      get services_list_dashboard_branch_operations_path(branch),
          headers: browser_headers.merge("Accept" => "application/json")
      json = JSON.parse(response.body)

      expect(json.length).to eq(1)
      expect(json.first).to include("id", "name", "duration_minutes", "price_cents")
      expect(json.first["name"]).to eq("Haircut")
    end
  end

  # ---------------------------------------------------------------------------
  # POST /dashboard/branches/:branch_id/bookings (JSON — walk-in)
  # ---------------------------------------------------------------------------
  describe "POST /dashboard/branches/:branch_id/bookings (JSON)" do
    let!(:service) { create(:service, branch: branch) }

    it "creates a walk-in booking and returns 201 with status" do
      post dashboard_branch_bookings_path(branch),
           params: {
             booking: {
               customer_name: "Walk In",
               customer_phone: "0901234567",
               service_ids: [ service.id ],
               source: "walk_in",
               status: "in_progress"
             }
           },
           headers: browser_headers,
           as: :json

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json["status"]).to eq("in_progress")
    end

    it "returns 422 with errors for missing required fields" do
      post dashboard_branch_bookings_path(branch),
           params: { booking: { customer_name: "", customer_phone: "" } },
           headers: browser_headers,
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json["errors"]).to be_present
    end
  end

  # ---------------------------------------------------------------------------
  # PATCH status transitions (JSON)
  # ---------------------------------------------------------------------------
  describe "PATCH status transitions" do
    let!(:confirmed_booking) do
      create(:booking, branch: branch, status: :confirmed, scheduled_at: 1.hour.from_now)
    end

    it "starts a booking and returns JSON with updated status" do
      patch start_dashboard_branch_booking_path(branch, confirmed_booking),
            headers: browser_headers,
            as: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["status"]).to eq("in_progress")
      expect(confirmed_booking.reload.status).to eq("in_progress")
    end

    it "completes a booking and returns JSON with updated status" do
      confirmed_booking.update!(status: :in_progress, started_at: Time.current)

      patch complete_dashboard_branch_booking_path(branch, confirmed_booking),
            headers: browser_headers,
            as: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["status"]).to eq("completed")
      expect(confirmed_booking.reload.status).to eq("completed")
    end

    it "cancels a booking and returns JSON" do
      patch cancel_dashboard_branch_booking_path(branch, confirmed_booking),
            headers: browser_headers,
            as: :json

      expect(response).to have_http_status(:ok)
      expect(confirmed_booking.reload.status).to eq("cancelled")
    end

    it "marks no_show and returns JSON" do
      patch no_show_dashboard_branch_booking_path(branch, confirmed_booking),
            headers: browser_headers,
            as: :json

      expect(response).to have_http_status(:ok)
      expect(confirmed_booking.reload.status).to eq("no_show")
    end
  end
end

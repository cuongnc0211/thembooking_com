require "rails_helper"

RSpec.describe "Dashboard::Bookings", type: :request do
  let(:user) { create(:user) }
  let(:business) { create(:business, user: user, capacity: 3) }
  let(:service) { create(:service, business: business, name: "Haircut", duration_minutes: 30) }
  let(:other_user) { create(:user, email_address: "other@example.com") }
  let(:other_business) { create(:business, user: other_user, slug: "other-shop") }

  # Helper to simulate logged in user
  def sign_in(user)
    post session_path, params: { email_address: user.email_address, password: "password123" }
  end

  describe "authentication" do
    it "redirects to login when not authenticated" do
      get dashboard_bookings_path
      expect(response).to redirect_to(new_session_path)
    end
  end

  describe "business setup requirement" do
    before { sign_in(user) }

    it "redirects to business setup when user has no business" do
      user.business&.destroy # Ensure no business
      get dashboard_bookings_path
      expect(response).to redirect_to(new_dashboard_business_path)
    end
  end

  describe "GET /dashboard/bookings (index)" do
    before do
      sign_in(user)
      business # Ensure business exists
    end

    context "default view (today's bookings)" do
      let!(:today_morning) do
        create(:booking, :walk_in,
          business: business,
          scheduled_at: Time.current.change(hour: 9, min: 0),
          customer_name: "John Doe",
          status: :confirmed)
      end
      let!(:today_afternoon) do
        create(:booking, :walk_in,
          business: business,
          scheduled_at: Time.current.change(hour: 14, min: 0),
          customer_name: "Jane Smith",
          status: :in_progress)
      end
      let!(:yesterday_booking) do
        create(:booking, :walk_in,
          business: business,
          scheduled_at: 1.day.ago,
          customer_name: "Past Customer",
          status: :completed)
      end
      let!(:tomorrow_booking) do
        create(:booking, # Online booking for future is valid
          business: business,
          scheduled_at: 1.day.from_now,
          customer_name: "Future Customer",
          status: :pending)
      end

      it "shows only today's bookings by default" do
        get dashboard_bookings_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include("John Doe")
        expect(response.body).to include("Jane Smith")
        expect(response.body).not_to include("Past Customer")
        expect(response.body).not_to include("Future Customer")
      end

      it "sorts bookings by scheduled_at time" do
        get dashboard_bookings_path
        expect(response).to have_http_status(:success)
        # Morning booking (9:00) should appear before afternoon booking (14:00)
        expect(response.body.index("John Doe")).to be < response.body.index("Jane Smith")
      end

      it "displays booking status" do
        get dashboard_bookings_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include("confirmed")
        expect(response.body).to include("in_progress")
      end

      it "shows capacity indicator with current usage" do
        # today_afternoon is in_progress, so 1/3 occupied
        get dashboard_bookings_path
        expect(response).to have_http_status(:success)
        expect(response.body).to match(/1.*\/.*3/) # Matches "1/3" or "1 / 3"
      end
    end

    context "date filtering" do
      let(:specific_date) { Date.new(2025, 12, 15) }
      let!(:booking_on_date) do
        create(:booking,
          business: business,
          scheduled_at: specific_date.beginning_of_day + 10.hours,
          customer_name: "Specific Date Customer")
      end

      it "filters bookings by date parameter" do
        get dashboard_bookings_path, params: { date: specific_date.to_s }
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Specific Date Customer")
      end

      it "does not show bookings from other dates" do
        create(:booking,
          business: business,
          scheduled_at: specific_date + 1.day,
          customer_name: "Next Day Customer")

        get dashboard_bookings_path, params: { date: specific_date.to_s }
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Specific Date Customer")
        expect(response.body).not_to include("Next Day Customer")
      end
    end

    context "status filtering" do
      before do
        create(:booking, :walk_in, business: business, scheduled_at: Time.current, customer_name: "Pending Customer", status: :pending)
        create(:booking, :walk_in, business: business, scheduled_at: Time.current, customer_name: "Confirmed Customer", status: :confirmed)
        create(:booking, :walk_in, business: business, scheduled_at: Time.current, customer_name: "In Progress Customer", status: :in_progress)
        create(:booking, :walk_in, business: business, scheduled_at: Time.current, customer_name: "Completed Customer", status: :completed)
      end

      it "filters bookings by pending status" do
        get dashboard_bookings_path, params: { status: "pending" }
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Pending Customer")
        expect(response.body).not_to include("Confirmed Customer")
        expect(response.body).not_to include("In Progress Customer")
      end

      it "filters bookings by confirmed status" do
        get dashboard_bookings_path, params: { status: "confirmed" }
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Confirmed Customer")
        expect(response.body).not_to include("Pending Customer")
      end

      it "filters bookings by in_progress status" do
        get dashboard_bookings_path, params: { status: "in_progress" }
        expect(response).to have_http_status(:success)
        expect(response.body).to include("In Progress Customer")
        expect(response.body).not_to include("Pending Customer")
      end

      it "shows all bookings when no status filter applied" do
        get dashboard_bookings_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Pending Customer")
        expect(response.body).to include("Confirmed Customer")
        expect(response.body).to include("In Progress Customer")
      end
    end

    context "search functionality" do
      before do
        create(:booking, :walk_in,
          business: business,
          scheduled_at: Time.current,
          customer_name: "Alice Johnson",
          customer_phone: "0123456789")
        create(:booking, :walk_in,
          business: business,
          scheduled_at: Time.current,
          customer_name: "Bob Williams",
          customer_phone: "0987654321")
      end

      it "searches bookings by customer name" do
        get dashboard_bookings_path, params: { search: "Alice" }
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Alice Johnson")
        expect(response.body).not_to include("Bob Williams")
      end

      it "searches bookings by customer phone" do
        get dashboard_bookings_path, params: { search: "0123456789" }
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Alice Johnson")
        expect(response.body).not_to include("Bob Williams")
      end

      it "is case insensitive" do
        get dashboard_bookings_path, params: { search: "alice" }
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Alice Johnson")
      end
    end

    context "service filtering" do
      let(:service1) { create(:service, business: business, name: "Haircut") }
      let(:service2) { create(:service, business: business, name: "Massage") }

      before do
        booking1 = create(:booking, :walk_in,
          business: business,
          scheduled_at: Time.current,
          customer_name: "Haircut Customer")
        create(:booking_service, booking: booking1, service: service1)

        booking2 = create(:booking, :walk_in,
          business: business,
          scheduled_at: Time.current,
          customer_name: "Massage Customer")
        create(:booking_service, booking: booking2, service: service2)
      end

      it "filters bookings by service" do
        get dashboard_bookings_path, params: { service_id: service1.id }
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Haircut Customer")
        expect(response.body).not_to include("Massage Customer")
      end

      it "shows all bookings when no service filter applied" do
        get dashboard_bookings_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Haircut Customer")
        expect(response.body).to include("Massage Customer")
      end
    end

    context "business isolation" do
      let!(:my_booking) do
        create(:booking, :walk_in,
          business: business,
          scheduled_at: Time.current,
          customer_name: "My Customer")
      end
      let!(:other_booking) do
        create(:booking, :walk_in,
          business: other_business,
          scheduled_at: Time.current,
          customer_name: "Other Business Customer")
      end

      it "only shows bookings for current user's business" do
        get dashboard_bookings_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include("My Customer")
        expect(response.body).not_to include("Other Business Customer")
      end
    end

    context "capacity calculation" do
      before do
        # Clear any existing bookings
        business.bookings.destroy_all
      end

      it "shows 0/3 when no bookings in progress" do
        create(:booking, :walk_in, business: business, scheduled_at: Time.current, status: :pending)
        create(:booking, :walk_in, business: business, scheduled_at: Time.current, status: :confirmed)

        get dashboard_bookings_path
        expect(response).to have_http_status(:success)
        expect(response.body).to match(/0.*\/.*3/)
      end

      it "counts only in_progress bookings for capacity" do
        create(:booking, :walk_in, business: business, scheduled_at: Time.current, status: :in_progress)
        create(:booking, :walk_in, business: business, scheduled_at: Time.current, status: :in_progress)
        create(:booking, :walk_in, business: business, scheduled_at: Time.current, status: :confirmed)

        get dashboard_bookings_path
        expect(response).to have_http_status(:success)
        expect(response.body).to match(/2.*\/.*3/)
      end

      it "shows 3/3 when at full capacity" do
        create(:booking, :walk_in, business: business, scheduled_at: Time.current, status: :in_progress)
        create(:booking, :walk_in, business: business, scheduled_at: Time.current, status: :in_progress)
        create(:booking, :walk_in, business: business, scheduled_at: Time.current, status: :in_progress)

        get dashboard_bookings_path
        expect(response).to have_http_status(:success)
        expect(response.body).to match(/3.*\/.*3/)
      end
    end

    context "date navigation" do
      it "shows date navigation controls" do
        get dashboard_bookings_path
        expect(response).to have_http_status(:success)
        # Should have prev/next navigation
        expect(response.body).to include("Previous").or include("←")
        expect(response.body).to include("Next").or include("→")
      end

      it "displays the current date being viewed" do
        get dashboard_bookings_path
        expect(response).to have_http_status(:success)
        # Check for either the full date format or "Today"
        expect(response.body).to include(Date.current.strftime("%B %d, %Y")).or include("Today")
      end
    end
  end
end

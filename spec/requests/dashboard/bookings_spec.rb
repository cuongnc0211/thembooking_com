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

  describe "Status Transition Actions" do
    before do
      sign_in(user)
      business # Ensure business exists
    end

    let!(:booking) do
      create(:booking, :walk_in,
        business: business,
        scheduled_at: Time.current,
        customer_name: "Test Customer",
        status: :pending)
    end

    describe "PATCH /dashboard/bookings/:id/confirm" do
      it "changes status from pending to confirmed" do
        expect {
          patch confirm_dashboard_booking_path(booking)
        }.to change { booking.reload.status }.from("pending").to("confirmed")
      end

      it "redirects to bookings index with success message" do
        patch confirm_dashboard_booking_path(booking)
        expect(response).to redirect_to(dashboard_bookings_path)
        follow_redirect!
        expect(response.body).to include("Booking confirmed")
      end

      it "does not allow confirming other business's bookings" do
        other_booking = create(:booking, :walk_in, business: other_business, scheduled_at: Time.current, status: :pending)
        patch confirm_dashboard_booking_path(other_booking)
        expect(response).to have_http_status(:not_found)
      end
    end

    describe "PATCH /dashboard/bookings/:id/start" do
      before { booking.update(status: :confirmed) }

      it "changes status from confirmed to in_progress" do
        expect {
          patch start_dashboard_booking_path(booking)
        }.to change { booking.reload.status }.from("confirmed").to("in_progress")
      end

      it "records started_at timestamp" do
        expect {
          patch start_dashboard_booking_path(booking)
        }.to change { booking.reload.started_at }.from(nil).to(be_within(1.second).of(Time.current))
      end

      it "redirects to bookings index with success message" do
        patch start_dashboard_booking_path(booking)
        expect(response).to redirect_to(dashboard_bookings_path)
        follow_redirect!
        expect(response.body).to include("Service started")
      end

      it "does not allow starting other business's bookings" do
        other_booking = create(:booking, :walk_in, business: other_business, scheduled_at: Time.current, status: :confirmed)
        patch start_dashboard_booking_path(other_booking)
        expect(response).to have_http_status(:not_found)
      end
    end

    describe "PATCH /dashboard/bookings/:id/complete" do
      before { booking.update(status: :in_progress, started_at: 1.hour.ago) }

      it "changes status from in_progress to completed" do
        expect {
          patch complete_dashboard_booking_path(booking)
        }.to change { booking.reload.status }.from("in_progress").to("completed")
      end

      it "records completed_at timestamp" do
        expect {
          patch complete_dashboard_booking_path(booking)
        }.to change { booking.reload.completed_at }.from(nil).to(be_within(1.second).of(Time.current))
      end

      it "redirects to bookings index with success message" do
        patch complete_dashboard_booking_path(booking)
        expect(response).to redirect_to(dashboard_bookings_path)
        follow_redirect!
        expect(response.body).to include("Booking completed")
      end

      it "does not allow completing other business's bookings" do
        other_booking = create(:booking, :walk_in, business: other_business, scheduled_at: Time.current, status: :in_progress)
        patch complete_dashboard_booking_path(other_booking)
        expect(response).to have_http_status(:not_found)
      end
    end

    describe "PATCH /dashboard/bookings/:id/cancel" do
      it "changes status to cancelled" do
        expect {
          patch cancel_dashboard_booking_path(booking)
        }.to change { booking.reload.status }.from("pending").to("cancelled")
      end

      it "can cancel from confirmed status" do
        booking.update(status: :confirmed)
        expect {
          patch cancel_dashboard_booking_path(booking)
        }.to change { booking.reload.status }.from("confirmed").to("cancelled")
      end

      it "can cancel from in_progress status" do
        booking.update(status: :in_progress)
        expect {
          patch cancel_dashboard_booking_path(booking)
        }.to change { booking.reload.status }.from("in_progress").to("cancelled")
      end

      it "redirects to bookings index with success message" do
        patch cancel_dashboard_booking_path(booking)
        expect(response).to redirect_to(dashboard_bookings_path)
        follow_redirect!
        expect(response.body).to include("Booking cancelled")
      end

      it "does not allow cancelling other business's bookings" do
        other_booking = create(:booking, :walk_in, business: other_business, scheduled_at: Time.current, status: :pending)
        patch cancel_dashboard_booking_path(other_booking)
        expect(response).to have_http_status(:not_found)
      end
    end

    describe "PATCH /dashboard/bookings/:id/no_show" do
      before { booking.update(status: :confirmed) }

      it "changes status to no_show" do
        expect {
          patch no_show_dashboard_booking_path(booking)
        }.to change { booking.reload.status }.from("confirmed").to("no_show")
      end

      it "can mark no_show from in_progress status" do
        booking.update(status: :in_progress)
        expect {
          patch no_show_dashboard_booking_path(booking)
        }.to change { booking.reload.status }.from("in_progress").to("no_show")
      end

      it "redirects to bookings index with success message" do
        patch no_show_dashboard_booking_path(booking)
        expect(response).to redirect_to(dashboard_bookings_path)
        follow_redirect!
        expect(response.body).to include("Marked as no-show")
      end

      it "does not allow marking no_show for other business's bookings" do
        other_booking = create(:booking, :walk_in, business: other_business, scheduled_at: Time.current, status: :confirmed)
        patch no_show_dashboard_booking_path(other_booking)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "Walk-in Quick Add" do
    before do
      sign_in(user)
      business # Ensure business exists
    end

    let(:service1) { create(:service, business: business, name: "Haircut", duration_minutes: 30) }
    let(:service2) { create(:service, business: business, name: "Shave", duration_minutes: 15) }

    describe "GET /dashboard/bookings/new" do
      it "renders the walk-in form" do
        get new_dashboard_booking_path
        expect(response).to have_http_status(:success)
      end

      it "displays all active services" do
        service1 # Create services
        service2
        get new_dashboard_booking_path
        expect(response.body).to include("Haircut")
        expect(response.body).to include("Shave")
      end

      it "shows customer input fields" do
        get new_dashboard_booking_path
        expect(response.body).to include("customer_name")
        expect(response.body).to include("customer_phone")
      end
    end

    describe "POST /dashboard/bookings" do
      let(:valid_params) do
        {
          booking: {
            customer_name: "Walk-in Customer",
            customer_phone: "0123456789",
            customer_email: "walkin@example.com",
            notes: "Quick haircut",
            service_ids: [ service1.id ]
          }
        }
      end

      context "with valid params" do
        it "creates a new booking" do
          expect {
            post dashboard_bookings_path, params: valid_params
          }.to change(Booking, :count).by(1)
        end

        it "sets source to walk_in" do
          post dashboard_bookings_path, params: valid_params
          expect(Booking.last.source).to eq("walk_in")
        end

        it "sets status to in_progress" do
          post dashboard_bookings_path, params: valid_params
          expect(Booking.last.status).to eq("in_progress")
        end

        it "sets scheduled_at to current time" do
          post dashboard_bookings_path, params: valid_params
          expect(Booking.last.scheduled_at).to be_within(1.second).of(Time.current)
        end

        it "associates with selected services" do
          post dashboard_bookings_path, params: valid_params
          expect(Booking.last.services).to include(service1)
        end

        it "associates with current business" do
          post dashboard_bookings_path, params: valid_params
          expect(Booking.last.business).to eq(business)
        end

        it "redirects to bookings index with success message" do
          post dashboard_bookings_path, params: valid_params
          expect(response).to redirect_to(dashboard_bookings_path)
          follow_redirect!
          expect(response.body).to include("Walk-in customer added successfully")
        end

        it "works with multiple services" do
          params = valid_params.deep_merge(booking: { service_ids: [ service1.id, service2.id ] })
          post dashboard_bookings_path, params: params
          expect(Booking.last.services.count).to eq(2)
        end

        it "phone is optional for walk-ins but uses default validation" do
          params = valid_params.deep_merge(booking: { customer_phone: "" })
          post dashboard_bookings_path, params: params
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it "email is optional for walk-ins" do
          params = valid_params.deep_merge(booking: { customer_email: "" })
          post dashboard_bookings_path, params: params
          expect(response).to redirect_to(dashboard_bookings_path)
        end
      end

      context "with invalid params" do
        it "requires customer name" do
          params = valid_params.deep_merge(booking: { customer_name: "" })
          expect {
            post dashboard_bookings_path, params: params
          }.not_to change(Booking, :count)
        end

        it "requires at least one service" do
          params = valid_params.deep_merge(booking: { service_ids: [] })
          expect {
            post dashboard_bookings_path, params: params
          }.not_to change(Booking, :count)
        end

        it "renders the form with errors" do
          params = valid_params.deep_merge(booking: { customer_name: "" })
          post dashboard_bookings_path, params: params
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body).to include("customer_name")
        end

        it "validates phone format" do
          params = valid_params.deep_merge(booking: { customer_phone: "invalid" })
          post dashboard_bookings_path, params: params
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end

  describe "GET /dashboard/bookings/:id (show)" do
    before do
      sign_in(user)
      business # Ensure business exists
    end

    let(:service1) { create(:service, business: business, name: "Haircut", duration_minutes: 30, price_cents: 15000000) }
    let(:service2) { create(:service, business: business, name: "Shave", duration_minutes: 15, price_cents: 5000000) }
    let(:booking) do
      create(:booking, :walk_in,
        business: business,
        scheduled_at: Time.current,
        status: :confirmed,
        customer_name: "John Doe",
        customer_phone: "0123456789",
        customer_email: "john@example.com",
        notes: "Please use scissors only").tap do |b|
          b.services << service1
          b.services << service2
        end
    end

    it "displays booking details" do
      get dashboard_booking_path(booking)
      expect(response).to have_http_status(:success)
      expect(response.body).to include("John Doe")
      expect(response.body).to include("0123456789")
      expect(response.body).to include("john@example.com")
      expect(response.body).to include("Please use scissors only")
    end

    it "displays associated services" do
      get dashboard_booking_path(booking)
      expect(response.body).to include("Haircut")
      expect(response.body).to include("Shave")
      expect(response.body).to include("30")
      expect(response.body).to include("15")
    end

    it "displays booking status" do
      get dashboard_booking_path(booking)
      expect(response.body).to include("Confirmed")
    end

    it "displays booking source" do
      get dashboard_booking_path(booking)
      expect(response.body).to include("Walk In")
    end

    it "shows edit button" do
      get dashboard_booking_path(booking)
      expect(response.body).to include("Edit")
    end

    it "does not allow viewing other business's bookings" do
      other_booking = create(:booking, :walk_in, business: other_business, scheduled_at: Time.current)
      get dashboard_booking_path(other_booking)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /dashboard/bookings/:id/edit (edit)" do
    before do
      sign_in(user)
      business # Ensure business exists
    end

    let(:service1) { create(:service, business: business, name: "Haircut") }
    let(:booking) { create(:booking, :walk_in, business: business, scheduled_at: Time.current, status: :confirmed) }

    it "renders the edit form" do
      get edit_dashboard_booking_path(booking)
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Edit Booking")
    end

    it "shows customer information in form" do
      get edit_dashboard_booking_path(booking)
      expect(response.body).to include(booking.customer_name)
      expect(response.body).to include(booking.customer_phone)
    end

    it "displays all active services for selection" do
      service1 # Create service
      get edit_dashboard_booking_path(booking)
      expect(response.body).to include("Haircut")
    end

    it "does not allow editing other business's bookings" do
      other_booking = create(:booking, :walk_in, business: other_business, scheduled_at: Time.current)
      get edit_dashboard_booking_path(other_booking)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /dashboard/bookings/:id (update)" do
    before do
      sign_in(user)
      business # Ensure business exists
    end

    let(:service1) { create(:service, business: business, name: "Haircut") }
    let(:service2) { create(:service, business: business, name: "Shave") }
    let(:booking) { create(:booking, :walk_in, business: business, scheduled_at: Time.current, status: :confirmed) }

    let(:valid_update_params) do
      {
        booking: {
          customer_name: "Updated Name",
          customer_phone: "0987654321",
          customer_email: "updated@example.com",
          notes: "Updated notes",
          service_ids: [ service1.id, service2.id ]
        }
      }
    end

    context "with valid params" do
      it "updates the booking" do
        patch dashboard_booking_path(booking), params: valid_update_params
        booking.reload
        expect(booking.customer_name).to eq("Updated Name")
        expect(booking.customer_phone).to eq("0987654321")
        expect(booking.customer_email).to eq("updated@example.com")
        expect(booking.notes).to eq("Updated notes")
      end

      it "updates associated services" do
        patch dashboard_booking_path(booking), params: valid_update_params
        booking.reload
        expect(booking.services).to include(service1)
        expect(booking.services).to include(service2)
        expect(booking.services.count).to eq(2)
      end

      it "redirects to booking show page" do
        patch dashboard_booking_path(booking), params: valid_update_params
        expect(response).to redirect_to(dashboard_booking_path(booking))
      end

      it "shows success message" do
        patch dashboard_booking_path(booking), params: valid_update_params
        follow_redirect!
        expect(response.body).to include("Booking updated successfully")
      end
    end

    context "with invalid params" do
      it "does not update with blank customer name" do
        params = valid_update_params.deep_merge(booking: { customer_name: "" })
        patch dashboard_booking_path(booking), params: params
        expect(response).to have_http_status(:unprocessable_entity)
        booking.reload
        expect(booking.customer_name).not_to eq("")
      end

      it "does not update with invalid phone format" do
        params = valid_update_params.deep_merge(booking: { customer_phone: "invalid" })
        patch dashboard_booking_path(booking), params: params
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "renders the edit form with errors" do
        params = valid_update_params.deep_merge(booking: { customer_name: "" })
        patch dashboard_booking_path(booking), params: params
        expect(response.body).to include("Edit Booking")
      end
    end

    it "does not allow updating other business's bookings" do
      other_booking = create(:booking, :walk_in, business: other_business, scheduled_at: Time.current)
      patch dashboard_booking_path(other_booking), params: valid_update_params
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "Real-Time Updates with Turbo Streams" do
    # Note: These tests verify that Turbo Stream broadcasts are configured.
    # Actual WebSocket broadcasting requires ActionCable setup and is tested in system/integration tests.

    describe "Booking model has broadcast callbacks" do
      it "has after_create_commit callback for broadcasting" do
        callbacks = Booking._commit_callbacks.select { |cb| cb.kind == :after && cb.filter == :broadcast_booking_created }
        expect(callbacks).not_to be_empty
      end

      it "has after_update_commit callback for broadcasting" do
        callbacks = Booking._commit_callbacks.select { |cb| cb.kind == :after && cb.filter == :broadcast_booking_updated }
        expect(callbacks).not_to be_empty
      end

      it "has after_destroy_commit callback for broadcasting" do
        callbacks = Booking._commit_callbacks.select { |cb| cb.kind == :after && cb.filter == :broadcast_booking_destroyed }
        expect(callbacks).not_to be_empty
      end
    end

    describe "broadcast methods are defined" do
      let(:booking) { build(:booking, :walk_in, business: business, scheduled_at: Time.current) }

      it "responds to broadcast_refresh_to_business (private method)" do
        expect(booking.private_methods).to include(:broadcast_refresh_to_business)
      end

      it "responds to broadcast_booking_created (private method)" do
        expect(booking.private_methods).to include(:broadcast_booking_created)
      end

      it "responds to broadcast_booking_updated (private method)" do
        expect(booking.private_methods).to include(:broadcast_booking_updated)
      end

      it "responds to broadcast_booking_destroyed (private method)" do
        expect(booking.private_methods).to include(:broadcast_booking_destroyed)
      end
    end
  end
end

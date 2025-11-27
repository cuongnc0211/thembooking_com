require "rails_helper"

RSpec.describe "Bookings", type: :request do
  let(:business) { create(:business, slug: "johns-barbershop") }
  let(:service1) { create(:service, business: business, duration_minutes: 30, price_cents: 80000) }
  let(:service2) { create(:service, business: business, duration_minutes: 15, price_cents: 50000) }

  before do
    # Setup operating hours
    business.update!(
      operating_hours: {
        "wednesday" => { "open" => "09:00", "close" => "17:00", "closed" => false },
        "saturday" => { "closed" => true }
      }
    )
  end

  describe "GET /:business_slug (new)" do
    it "displays the booking page" do
      get "/#{business.slug}"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(business.name)
    end

    it "lists all active services" do
      service1 # Create services
      service2
      inactive_service = create(:service, business: business, active: false)

      get "/#{business.slug}"

      expect(response.body).to include(service1.name)
      expect(response.body).to include(service2.name)
      expect(response.body).not_to include(inactive_service.name)
    end

    it "returns 404 for non-existent business" do
      expect {
        get "/non-existent-business"
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "is accessible without authentication" do
      # No authentication required - this is public endpoint
      get "/#{business.slug}"

      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /:business_slug/availability" do
    let(:date) { Date.new(2025, 11, 27) } # Wednesday

    context "with valid parameters" do
      it "returns available time slots as JSON" do
        get "/#{business.slug}/availability",
            params: { service_ids: [service1.id], date: date.to_s }

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to match(%r{application/json})

        json = JSON.parse(response.body)
        expect(json["available_slots"]).to be_an(Array)
      end

      it "calculates availability based on multiple services" do
        get "/#{business.slug}/availability",
            params: { service_ids: [service1.id, service2.id], date: date.to_s }

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        # Should consider total duration (30 + 15 = 45 minutes)
        expect(json["available_slots"]).to be_an(Array)
      end

      it "returns empty array for closed days" do
        saturday = Date.new(2025, 11, 29) # Saturday (closed)

        get "/#{business.slug}/availability",
            params: { service_ids: [service1.id], date: saturday.to_s }

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json["available_slots"]).to eq([])
      end
    end

    context "with invalid parameters" do
      it "returns error when service_ids is empty" do
        get "/#{business.slug}/availability",
            params: { service_ids: [], date: date.to_s }

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json["available_slots"]).to eq([])
      end

      it "returns 404 for non-existent business" do
        expect {
          get "/non-existent-business/availability",
              params: { service_ids: [service1.id], date: date.to_s }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "POST /:business_slug/bookings (create)" do
    let(:scheduled_at) { Time.zone.parse("2025-11-27 10:00") }
    let(:booking_params) do
      {
        service_ids: [service1.id, service2.id],
        scheduled_at: scheduled_at.iso8601,
        booking: {
          customer_name: "Nguyen Van A",
          customer_phone: "0912345678",
          customer_email: "customer@example.com",
          notes: "Please use side entrance"
        }
      }
    end

    context "with valid parameters" do
      it "creates a new booking" do
        expect {
          post "/#{business.slug}/bookings", params: booking_params
        }.to change { Booking.count }.by(1)

        booking = Booking.last
        expect(booking.services).to contain_exactly(service1, service2)
        expect(booking.customer_name).to eq("Nguyen Van A")
      end

      it "redirects to confirmation page" do
        post "/#{business.slug}/bookings", params: booking_params

        booking = Booking.last
        expect(response).to redirect_to("/#{business.slug}/bookings/#{booking.id}")
      end

      it "sets booking status to pending and source to online" do
        post "/#{business.slug}/bookings", params: booking_params

        booking = Booking.last
        expect(booking.status).to eq("pending")
        expect(booking.source).to eq("online")
      end
    end

    context "with invalid parameters" do
      it "re-renders the new page with errors when customer_name is missing" do
        invalid_params = booking_params.deep_merge(booking: { customer_name: nil })

        post "/#{business.slug}/bookings", params: invalid_params

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("Customer name")
      end

      it "re-renders the new page when phone format is invalid" do
        invalid_params = booking_params.deep_merge(booking: { customer_phone: "123" })

        post "/#{business.slug}/bookings", params: invalid_params

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("Customer phone")
      end

      it "does not create booking when validation fails" do
        invalid_params = booking_params.deep_merge(booking: { customer_name: nil })

        expect {
          post "/#{business.slug}/bookings", params: invalid_params
        }.not_to change { Booking.count }
      end
    end

    context "when slot is unavailable" do
      before do
        # Fill capacity
        business.update!(capacity: 1)
        existing_booking = create(:booking, business: business, scheduled_at: scheduled_at, status: :confirmed)
        existing_booking.services << service1
      end

      it "shows error message and re-renders form" do
        post "/#{business.slug}/bookings", params: booking_params

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("no longer available")
      end

      it "does not create booking" do
        expect {
          post "/#{business.slug}/bookings", params: booking_params
        }.not_to change { Booking.count }
      end
    end

    context "when services don't belong to business" do
      let(:other_business) { create(:business) }
      let(:other_service) { create(:service, business: other_business) }

      it "returns error and does not create booking" do
        invalid_params = booking_params.merge(service_ids: [other_service.id])

        expect {
          post "/#{business.slug}/bookings", params: invalid_params
        }.not_to change { Booking.count }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("do not belong")
      end
    end

    it "is accessible without authentication" do
      post "/#{business.slug}/bookings", params: booking_params

      expect(response).to have_http_status(:found) # Redirect to confirmation
    end
  end

  describe "GET /:business_slug/bookings/:id (show)" do
    let(:booking) do
      booking = create(:booking, business: business, customer_name: "Nguyen Van A")
      booking.services << [service1, service2]
      booking
    end

    it "displays booking confirmation page" do
      get "/#{business.slug}/bookings/#{booking.id}"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Nguyen Van A")
      expect(response.body).to include(service1.name)
      expect(response.body).to include(service2.name)
    end

    it "shows booking reference number" do
      get "/#{business.slug}/bookings/#{booking.id}"

      expect(response.body).to include("#BK-#{booking.id}")
    end

    it "displays business contact information" do
      get "/#{business.slug}/bookings/#{booking.id}"

      expect(response.body).to include(business.name)
      expect(response.body).to include(business.phone) if business.phone
    end

    it "is accessible without authentication" do
      get "/#{business.slug}/bookings/#{booking.id}"

      expect(response).to have_http_status(:ok)
    end

    it "returns 404 for booking from different business" do
      other_business = create(:business, slug: "other-shop")
      other_booking = create(:booking, business: other_business)

      expect {
        get "/#{business.slug}/bookings/#{other_booking.id}"
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "returns 404 for non-existent booking" do
      expect {
        get "/#{business.slug}/bookings/999999"
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end

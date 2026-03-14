require "rails_helper"

RSpec.describe "Public Bookings", type: :request do
  let(:browser_headers) { { "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" } }
  let(:user) { create(:user) }
  let(:business) { create(:business, user: user) }
  let(:branch) { create(:branch, business: business, slug: "test-barber", active: true) }
  let!(:service) { create(:service, branch: branch, duration_minutes: 30) }

  describe "GET /:branch_slug" do
    context "with an active branch" do
      it "returns 200" do
        get booking_path(branch.slug), headers: browser_headers
        expect(response).to have_http_status(:ok)
      end
    end

    context "with an inactive branch" do
      before { branch.update!(active: false) }

      it "returns 404" do
        get booking_path(branch.slug), headers: browser_headers
        expect(response).to have_http_status(:not_found)
      end
    end

    context "with a non-existent slug" do
      it "returns 404" do
        get booking_path("nonexistent-slug"), headers: browser_headers
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET /:branch_slug/availability" do
    let(:date) { Date.tomorrow.to_s }

    context "with valid service_ids and date" do
      it "returns available slots JSON" do
        get "/#{branch.slug}/availability?date=#{date}&service_ids[]=#{service.id}", headers: browser_headers
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json).to have_key("available_slots")
        expect(json["available_slots"]).to be_an(Array)
      end
    end

    context "with no service_ids" do
      it "returns empty slots" do
        get "/#{branch.slug}/availability?date=#{date}", headers: browser_headers
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["available_slots"]).to eq([])
      end
    end

    context "with invalid date" do
      it "returns bad_request" do
        get "/#{branch.slug}/availability?date=not-a-date&service_ids[]=#{service.id}", headers: browser_headers
        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json["error"]).to eq("Invalid date")
      end
    end

    context "with inactive branch" do
      before { branch.update!(active: false) }

      it "returns 404" do
        get "/#{branch.slug}/availability?date=#{date}&service_ids[]=#{service.id}", headers: browser_headers
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "POST /:branch_slug/bookings" do
    let(:start_time) { "#{Date.tomorrow} 10:00" }
    let(:booking_params) do
      {
        service_ids: [ service.id ],
        start_time: start_time,
        booking: {
          customer_name: "Nguyen Van A",
          customer_phone: "0912345678"
        }
      }
    end

    context "with valid params" do
      it "creates a booking and redirects to confirmation" do
        expect {
          post "/#{branch.slug}/bookings", params: booking_params, headers: browser_headers
        }.to change(Booking, :count).by(1)
        expect(response).to redirect_to(booking_confirmation_path(branch.slug, Booking.last))
      end

      it "scopes booking to the correct branch" do
        post "/#{branch.slug}/bookings", params: booking_params, headers: browser_headers
        expect(Booking.last.branch).to eq(branch)
      end
    end

    context "with missing required params" do
      it "does not create a booking and returns unprocessable_entity" do
        expect {
          post "/#{branch.slug}/bookings", params: {
            service_ids: [ service.id ],
            start_time: start_time,
            booking: { customer_name: "", customer_phone: "" }
          }, headers: browser_headers
        }.not_to change(Booking, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "with inactive branch" do
      before { branch.update!(active: false) }

      it "returns 404 without creating a booking" do
        expect {
          post "/#{branch.slug}/bookings", params: booking_params, headers: browser_headers
        }.not_to change(Booking, :count)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET /:branch_slug/bookings/:id" do
    let(:booking) { create(:booking, branch: branch) }

    it "renders the confirmation page" do
      get booking_confirmation_path(branch.slug, booking), headers: browser_headers
      expect(response).to have_http_status(:ok)
    end

    it "returns 404 for booking on a different branch" do
      other_booking = create(:booking)
      get booking_confirmation_path(branch.slug, other_booking), headers: browser_headers
      expect(response).to have_http_status(:not_found)
    end
  end
end

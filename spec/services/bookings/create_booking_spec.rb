require "rails_helper"

RSpec.describe Bookings::CreateBooking do
  let(:business) { create(:business, capacity: 2) }
  let(:service1) { create(:service, business: business, duration_minutes: 30) }
  let(:service2) { create(:service, business: business, duration_minutes: 15) }
  let(:scheduled_at) { Time.zone.parse("2025-11-27 10:00") }
  let(:customer_params) do
    {
      customer_name: "Nguyen Van A",
      customer_phone: "0912345678",
      customer_email: "customer@example.com",
      notes: "Please use side entrance"
    }
  end

  before do
    # Setup operating hours
    business.update!(
      operating_hours: {
        "wednesday" => { "open" => "09:00", "close" => "17:00", "closed" => false }
      }
    )
  end

  describe "#call" do
    context "with valid parameters" do
      it "creates a booking with all services" do
        service = described_class.new(
          business: business,
          service_ids: [ service1.id, service2.id ],
          scheduled_at: scheduled_at,
          customer_params: customer_params
        )

        expect { service.call }.to change { Booking.count }.by(1)

        booking = Booking.last
        expect(booking.services).to contain_exactly(service1, service2)
        expect(booking.customer_name).to eq("Nguyen Van A")
        expect(booking.customer_phone).to eq("0912345678")
        expect(booking.customer_email).to eq("customer@example.com")
        expect(booking.notes).to eq("Please use side entrance")
        expect(booking.scheduled_at).to eq(scheduled_at)
      end

      it "sets status to pending and source to online" do
        service = described_class.new(
          business: business,
          service_ids: [ service1.id ],
          scheduled_at: scheduled_at,
          customer_params: customer_params
        )

        service.call

        booking = Booking.last
        expect(booking.status).to eq("pending")
        expect(booking.source).to eq("online")
      end

      it "returns success result with booking" do
        service = described_class.new(
          business: business,
          service_ids: [ service1.id ],
          scheduled_at: scheduled_at,
          customer_params: customer_params
        )

        result = service.call

        expect(result.success?).to be true
        expect(result.booking).to be_a(Booking)
        expect(result.booking).to be_persisted
      end
    end

    context "with invalid parameters" do
      it "returns error when customer_name is missing" do
        invalid_params = customer_params.merge(customer_name: nil)
        service = described_class.new(
          business: business,
          service_ids: [ service1.id ],
          scheduled_at: scheduled_at,
          customer_params: invalid_params
        )

        result = service.call

        expect(result.success?).to be false
        expect(result.error).to include("Customer name can't be blank")
      end

      it "returns error when customer_phone is invalid" do
        invalid_params = customer_params.merge(customer_phone: "123") # Invalid format
        service = described_class.new(
          business: business,
          service_ids: [ service1.id ],
          scheduled_at: scheduled_at,
          customer_params: invalid_params
        )

        result = service.call

        expect(result.success?).to be false
        expect(result.error).to include("Customer phone")
      end

      it "returns error when scheduled_at is in the past" do
        past_time = 1.hour.ago
        service = described_class.new(
          business: business,
          service_ids: [ service1.id ],
          scheduled_at: past_time,
          customer_params: customer_params
        )

        result = service.call

        expect(result.success?).to be false
        expect(result.error).to include("must be in the future")
      end

      it "returns error when no services are provided" do
        service = described_class.new(
          business: business,
          service_ids: [],
          scheduled_at: scheduled_at,
          customer_params: customer_params
        )

        result = service.call

        expect(result.success?).to be false
        expect(result.error).to include("Services must be provided")
      end
    end

    context "when services don't belong to business" do
      let(:other_business) { create(:business) }
      let(:other_service) { create(:service, business: other_business) }

      it "returns error" do
        service = described_class.new(
          business: business,
          service_ids: [ other_service.id ],
          scheduled_at: scheduled_at,
          customer_params: customer_params
        )

        result = service.call

        expect(result.success?).to be false
        expect(result.error).to include("services do not belong to this business")
      end

      it "does not create a booking" do
        service = described_class.new(
          business: business,
          service_ids: [ other_service.id ],
          scheduled_at: scheduled_at,
          customer_params: customer_params
        )

        expect { service.call }.not_to change { Booking.count }
      end
    end

    context "when slot becomes unavailable (race condition)" do
      it "returns error if capacity is exceeded" do
        # Create bookings that fill capacity
        2.times do
          booking = create(:booking, business: business, scheduled_at: scheduled_at, status: :confirmed)
          booking.services.clear
          booking.services << service1
          booking.save!
        end

        service = described_class.new(
          business: business,
          service_ids: [ service1.id ],
          scheduled_at: scheduled_at,
          customer_params: customer_params
        )

        result = service.call

        expect(result.success?).to be false
        expect(result.error).to include("time slot is no longer available")
      end

      it "does not create booking when slot is unavailable" do
        # Fill capacity
        2.times do
          booking = create(:booking, business: business, scheduled_at: scheduled_at, status: :confirmed)
          booking.services.clear
          booking.services << service1
          booking.save!
        end

        service = described_class.new(
          business: business,
          service_ids: [ service1.id ],
          scheduled_at: scheduled_at,
          customer_params: customer_params
        )

        expect { service.call }.not_to change { Booking.count }
      end
    end

    context "when checking availability" do
      it "only counts active bookings (confirmed, in_progress) for capacity check" do
        # Create cancelled and completed bookings - these should not affect capacity
        cancelled_booking = create(:booking, business: business, scheduled_at: scheduled_at, status: :cancelled)
        cancelled_booking.services << service1

        completed_booking = create(:booking, business: business, scheduled_at: scheduled_at, status: :completed)
        completed_booking.services << service1

        # Should still be able to book (capacity: 2, active bookings: 0)
        service = described_class.new(
          business: business,
          service_ids: [ service1.id ],
          scheduled_at: scheduled_at,
          customer_params: customer_params
        )

        result = service.call

        expect(result.success?).to be true
      end

      it "considers overlapping bookings based on total duration" do
        # Create booking at 10:00 with 30min service (ends at 10:30)
        existing_booking = create(:booking, business: business, scheduled_at: Time.zone.parse("2025-11-27 10:00"), status: :confirmed)
        existing_booking.services << service1

        # Try to book at 10:15 with 30min service (10:15-10:45, overlaps with 10:00-10:30)
        # Capacity is 2, so this should succeed
        service = described_class.new(
          business: business,
          service_ids: [ service1.id ],
          scheduled_at: Time.zone.parse("2025-11-27 10:15"),
          customer_params: customer_params
        )

        result = service.call
        expect(result.success?).to be true

        # Now add another overlapping booking to fill capacity
        second_booking = create(:booking, business: business, scheduled_at: Time.zone.parse("2025-11-27 10:20"), status: :confirmed)
        second_booking.services << service1

        # Third attempt should fail (capacity exceeded)
        third_service = described_class.new(
          business: business,
          service_ids: [ service1.id ],
          scheduled_at: Time.zone.parse("2025-11-27 10:25"),
          customer_params: customer_params
        )

        result = third_service.call
        expect(result.success?).to be false
      end
    end

    context "transaction and atomicity" do
      it "rolls back booking creation if service association fails" do
        # Use invalid service ID to trigger failure
        service = described_class.new(
          business: business,
          service_ids: [ 999999 ], # Non-existent ID
          scheduled_at: scheduled_at,
          customer_params: customer_params
        )

        expect { service.call }.not_to change { Booking.count }
      end
    end
  end
end

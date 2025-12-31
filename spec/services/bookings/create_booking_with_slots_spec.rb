require "rails_helper"

RSpec.describe Bookings::CreateBooking, type: :service do
  let(:business) { create(:business, capacity: 3) }
  let(:service_30min) { create(:service, business: business, duration_minutes: 30) }
  let(:service_60min) { create(:service, business: business, duration_minutes: 60) }
  let(:scheduled_at) { Time.zone.parse("2025-12-26 10:00") }
  let(:customer_params) do
    {
      customer_name: "Nguyen Van A",
      customer_phone: "0912345678",
      customer_email: "customer@example.com",
      notes: "Test booking"
    }
  end

  before do
    # Generate slots for the test date
    business.update!(
      operating_hours: {
        "friday" => { "open" => "09:00", "close" => "18:00", "closed" => false, "breaks" => [] }
      }
    )

    # Generate slots for Dec 26, 2025 (Friday)
    Slots::GenerateForBusiness.new(business: business, date: Date.new(2025, 12, 26)).call
  end

  describe "#call - slot-based booking" do
    context "with valid parameters and available slots" do
      it "creates a booking linked to appropriate slots" do
        result = described_class.new(
          business: business,
          service_ids: [ service_30min.id ],
          start_time: scheduled_at,
          customer_params: customer_params
        ).call

        expect(result[:success]).to be true

        booking = result[:booking]
        expect(booking).to be_persisted
        expect(booking.slots.count).to eq(2) # 30 min = 2 slots of 15 min
        expect(booking.slots.first.start_time).to eq(scheduled_at)
      end

      it "decrements slot capacity atomically" do
        # Check initial capacity
        slot1 = business.slots.find_by(start_time: scheduled_at)
        slot2 = business.slots.find_by(start_time: scheduled_at + 15.minutes)

        initial_capacity1 = slot1.capacity
        initial_capacity2 = slot2.capacity

        result = described_class.new(
          business: business,
          service_ids: [ service_30min.id ],
          start_time: scheduled_at,
          customer_params: customer_params
        ).call

        expect(result[:success]).to be true

        # Reload slots and check capacity decremented
        slot1.reload
        slot2.reload

        expect(slot1.capacity).to eq(initial_capacity1 - 1)
        expect(slot2.capacity).to eq(initial_capacity2 - 1)
      end

      it "creates booking_slot join records" do
        expect {
          described_class.new(
            business: business,
            service_ids: [ service_30min.id ],
            start_time: scheduled_at,
            customer_params: customer_params
          ).call
        }.to change { BookingSlot.count }.by(2) # 30 min = 2 slots
      end

      it "works for services requiring multiple slots (60 min = 4 slots)" do
        result = described_class.new(
          business: business,
          service_ids: [ service_60min.id ],
          start_time: scheduled_at,
          customer_params: customer_params
        ).call

        expect(result[:success]).to be true

        booking = result[:booking]
        expect(booking.slots.count).to eq(4) # 60 min = 4 slots of 15 min
      end

      it "handles multiple services correctly" do
        # 30min + 60min = 90min total = 6 slots
        result = described_class.new(
          business: business,
          service_ids: [ service_30min.id, service_60min.id ],
          start_time: scheduled_at,
          customer_params: customer_params
        ).call

        expect(result[:success]).to be true

        booking = result[:booking]
        expect(booking.slots.count).to eq(6) # 90 min = 6 slots
        expect(booking.services).to contain_exactly(service_30min, service_60min)
      end
    end

    context "when slots are not available (capacity exhausted)" do
      before do
        # Reduce slot capacity to 0 for target slots
        business.slots.where(
          "start_time >= ? AND start_time < ?",
          scheduled_at,
          scheduled_at + 30.minutes
        ).update_all(capacity: 0)
      end

      it "returns error when slots have no capacity" do
        result = described_class.new(
          business: business,
          service_ids: [ service_30min.id ],
          start_time: scheduled_at,
          customer_params: customer_params
        ).call

        expect(result[:success]).to be false
        expect(result[:error]).to include("Time slot no longer available")
      end

      it "does not create booking when slots unavailable" do
        expect {
          described_class.new(
            business: business,
            service_ids: [ service_30min.id ],
            start_time: scheduled_at,
            customer_params: customer_params
          ).call
        }.not_to change { Booking.count }
      end

      it "does not decrement slot capacity on failure" do
        slot = business.slots.find_by(start_time: scheduled_at)
        initial_capacity = slot.capacity

        described_class.new(
          business: business,
          service_ids: [ service_30min.id ],
          start_time: scheduled_at,
          customer_params: customer_params
        ).call

        slot.reload
        expect(slot.capacity).to eq(initial_capacity) # No change
      end
    end

    context "race condition handling with FOR UPDATE locks" do
      it "prevents double-booking with concurrent requests" do
        # Simulate two concurrent requests trying to book the last available slot
        slot = business.slots.find_by(start_time: scheduled_at)
        slot.update!(capacity: 1) # Only 1 slot available

        # First booking should succeed
        result1 = described_class.new(
          business: business,
          service_ids: [ service_30min.id ],
          start_time: scheduled_at,
          customer_params: customer_params
        ).call

        expect(result1[:success]).to be true

        # Second booking should fail (slot capacity now 0)
        result2 = described_class.new(
          business: business,
          service_ids: [ service_30min.id ],
          start_time: scheduled_at,
          customer_params: customer_params.merge(customer_name: "Different Customer")
        ).call

        expect(result2[:success]).to be false
        expect(result2[:error]).to include("Time slot no longer available")
      end

      it "locks slots with FOR UPDATE during transaction" do
        # This test verifies the lock is acquired by checking the SQL query
        # We can't easily mock Slot.lock because it's part of a query chain

        # Capture SQL queries
        queries = []
        subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |_name, _start, _finish, _id, payload|
          queries << payload[:sql]
        end

        described_class.new(
          business: business,
          service_ids: [ service_30min.id ],
          start_time: scheduled_at,
          customer_params: customer_params
        ).call

        ActiveSupport::Notifications.unsubscribe(subscriber)

        # Check that at least one query contains "FOR UPDATE"
        expect(queries.any? { |q| q.include?("FOR UPDATE") }).to be true
      end
    end

    context "when slots don't exist for the requested time" do
      it "returns error if no slots found" do
        # Try to book a time far in the future (no slots generated)
        future_time = Time.zone.parse("2026-01-01 10:00")

        result = described_class.new(
          business: business,
          service_ids: [ service_30min.id ],
          start_time: future_time,
          customer_params: customer_params
        ).call

        expect(result[:success]).to be false
        expect(result[:error]).to include("Time slot no longer available")
      end
    end

    context "when only partial slots are available" do
      before do
        # Make second slot unavailable (10:15-10:30)
        slot = business.slots.find_by(start_time: scheduled_at + 15.minutes)
        slot.update!(capacity: 0)
      end

      it "returns error if not all required slots have capacity" do
        # 30min service needs 2 consecutive slots, but only first is available
        result = described_class.new(
          business: business,
          service_ids: [ service_30min.id ],
          start_time: scheduled_at,
          customer_params: customer_params
        ).call

        expect(result[:success]).to be false
        expect(result[:error]).to include("Time slot no longer available")
      end
    end

    context "transaction rollback" do
      it "rolls back slot capacity changes if booking save fails" do
        # Make booking invalid (e.g., missing customer_name)
        invalid_params = customer_params.merge(customer_name: nil)

        slot = business.slots.find_by(start_time: scheduled_at)
        initial_capacity = slot.capacity

        result = described_class.new(
          business: business,
          service_ids: [ service_30min.id ],
          start_time: scheduled_at,
          customer_params: invalid_params
        ).call

        expect(result[:success]).to be false

        # Slot capacity should be unchanged (transaction rolled back)
        slot.reload
        expect(slot.capacity).to eq(initial_capacity)
      end

      it "does not create booking_slot records if transaction fails" do
        invalid_params = customer_params.merge(customer_name: nil)

        expect {
          described_class.new(
            business: business,
            service_ids: [ service_30min.id ],
            start_time: scheduled_at,
            customer_params: invalid_params
          ).call
        }.not_to change { BookingSlot.count }
      end
    end

    context "with invalid service IDs" do
      it "returns error when services don't belong to business" do
        other_business = create(:business)
        other_service = create(:service, business: other_business)

        result = described_class.new(
          business: business,
          service_ids: [ other_service.id ],
          start_time: scheduled_at,
          customer_params: customer_params
        ).call

        expect(result[:success]).to be false
        expect(result[:error]).to include("do not belong to this business")
      end

      it "returns error when no services provided" do
        result = described_class.new(
          business: business,
          service_ids: [],
          start_time: scheduled_at,
          customer_params: customer_params
        ).call

        expect(result[:success]).to be false
        expect(result[:error]).to include("Services must be provided")
      end
    end
  end
end

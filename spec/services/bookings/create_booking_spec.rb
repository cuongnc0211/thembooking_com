require "rails_helper"

RSpec.describe Bookings::CreateBooking, type: :service do
  let(:user) { create(:user) }
  let(:business) { create(:business, user: user, capacity: 1) }
  let(:service) { create(:service, business: business, duration_minutes: 30) }
  let(:start_time) { (Date.tomorrow.beginning_of_day + 10.hours).in_time_zone }
  let(:customer_params) { { customer_name: "Nguyen Van A", customer_phone: "0901234567" } }

  def call_service(start: start_time, service_ids: [service.id], customer_params: nil)
    customer_params ||= self.customer_params
    described_class.new(
      business: business,
      service_ids: service_ids,
      start_time: start,
      customer_params: customer_params
    ).call
  end

  describe "#call" do
    it "creates a booking with correct end_time" do
      result = call_service
      expect(result[:success]).to be true
      expect(result[:booking]).to be_persisted
      expect(result[:booking].end_time).to eq(start_time + 30.minutes)
    end

    it "sets booking status to pending" do
      result = call_service
      expect(result[:booking].status).to eq("pending")
    end

    it "sets booking source to online" do
      result = call_service
      expect(result[:booking].source).to eq("online")
    end

    it "associates services with booking" do
      result = call_service
      expect(result[:booking].services).to contain_exactly(service)
    end

    it "sets customer_name and customer_phone from customer_params" do
      result = call_service
      expect(result[:booking].customer_name).to eq("Nguyen Van A")
      expect(result[:booking].customer_phone).to eq("0901234567")
    end

    it "sets scheduled_at to the provided start_time" do
      result = call_service
      expect(result[:booking].scheduled_at).to eq(start_time)
    end

    context "with empty service_ids" do
      it "returns error" do
        result = call_service(service_ids: [])
        expect(result[:success]).to be false
        expect(result[:error]).to include("Services must be provided")
        expect(result[:booking]).to be_nil
      end
    end

    context "with invalid service_ids" do
      it "returns error when service doesn't belong to business" do
        other_business = create(:business, user: create(:user), slug: "other-shop")
        other_service = create(:service, business: other_business)

        result = call_service(service_ids: [other_service.id])
        expect(result[:success]).to be false
        expect(result[:error]).to include("One or more services do not belong to this business")
        expect(result[:booking]).to be_nil
      end

      it "returns error when service id doesn't exist" do
        result = call_service(service_ids: [99999])
        expect(result[:success]).to be false
        expect(result[:error]).to include("One or more services do not belong to this business")
      end
    end

    context "when time slot at full capacity" do
      it "rejects booking" do
        # Fill capacity
        create(:booking, business: business, scheduled_at: start_time, end_time: start_time + 30.minutes, status: :confirmed, services: [service])

        result = call_service
        expect(result[:success]).to be false
        expect(result[:error]).to include("no longer available")
        expect(result[:booking]).to be_nil
      end
    end

    context "with multiple services" do
      it "creates booking with combined duration" do
        service2 = create(:service, business: business, duration_minutes: 15)
        result = call_service(service_ids: [service.id, service2.id])

        expect(result[:success]).to be true
        expect(result[:booking].end_time).to eq(start_time + 45.minutes)
        expect(result[:booking].services).to contain_exactly(service, service2)
      end

      it "respects capacity with combined services" do
        service2 = create(:service, business: business, duration_minutes: 15)
        # Fill capacity with overlapping booking (30 + 15 = 45 minutes)
        create(:booking, business: business, scheduled_at: start_time, end_time: start_time + 60.minutes, status: :confirmed, services: [service])

        result = call_service(service_ids: [service.id, service2.id])
        expect(result[:success]).to be false
      end
    end

    context "with start_time as string" do
      it "parses start_time correctly" do
        result = described_class.new(
          business: business,
          service_ids: [service.id],
          start_time: start_time.to_s,
          customer_params: customer_params
        ).call

        expect(result[:success]).to be true
        expect(result[:booking].scheduled_at.to_i).to eq(start_time.to_i)
      end
    end

    context "with scheduled_at parameter (legacy support)" do
      it "works with scheduled_at instead of start_time" do
        result = described_class.new(
          business: business,
          service_ids: [service.id],
          scheduled_at: start_time,
          customer_params: customer_params
        ).call

        expect(result[:success]).to be true
        expect(result[:booking].scheduled_at).to eq(start_time)
      end
    end

    context "with missing customer_params" do
      it "returns error when customer_name is missing" do
        invalid_params = { customer_phone: "0901234567" }
        result = call_service(customer_params: invalid_params)

        expect(result[:success]).to be false
        expect(result[:booking]).to be_nil
      end

      it "returns error when customer_phone is missing" do
        invalid_params = { customer_name: "Nguyen Van A" }
        result = call_service(customer_params: invalid_params)

        expect(result[:success]).to be false
      end
    end

    context "with invalid customer_phone format" do
      it "returns error for invalid phone" do
        invalid_params = { customer_name: "Nguyen Van A", customer_phone: "123456789" }
        result = call_service(customer_params: invalid_params)

        expect(result[:success]).to be false
      end
    end

    context "concurrency with advisory locks" do
      it "uses PostgreSQL blocking advisory lock for business" do
        allow(ActiveRecord::Base.connection).to receive(:execute).and_call_original
        call_service
        # Verify pg_advisory_xact_lock (blocking form) was called with business id
        expect(ActiveRecord::Base.connection).to have_received(:execute).with(/pg_advisory_xact_lock/)
      end
    end

    context "when booking is not valid after lock" do
      it "rolls back transaction and returns error" do
        # Create a booking right before the service is called to cause validation conflict
        # This tests the rollback on invalid booking
        allow_any_instance_of(Booking).to receive(:valid?).and_return(false)

        result = call_service
        expect(result[:success]).to be false
        expect(result[:booking]).to be_nil
      end
    end

    context "when capacity increased" do
      it "allows multiple bookings up to capacity" do
        business.update(capacity: 2)
        service2 = create(:service, business: business, duration_minutes: 30)

        # First booking
        result1 = call_service(start: start_time)
        expect(result1[:success]).to be true

        # Second booking at same time
        result2 = described_class.new(
          business: business,
          service_ids: [service2.id],
          start_time: start_time,
          customer_params: customer_params
        ).call
        expect(result2[:success]).to be true

        # Third booking should fail
        result3 = described_class.new(
          business: business,
          service_ids: [service2.id],
          start_time: start_time,
          customer_params: { customer_name: "Nguyen Van B", customer_phone: "0912345678" }
        ).call
        expect(result3[:success]).to be false
      end
    end

    context "with cancelled and completed bookings" do
      it "does not count cancelled/completed bookings toward capacity check" do
        # Fill slot with cancelled booking
        create(:booking, business: business, scheduled_at: start_time, end_time: start_time + 30.minutes, status: :cancelled, services: [service])
        # Fill slot with completed booking
        create(:booking, business: business, scheduled_at: start_time, end_time: start_time + 30.minutes, status: :completed, services: [service])

        result = call_service
        expect(result[:success]).to be true
      end
    end

    context "return value structure" do
      it "returns hash with :success, :booking, and :error keys" do
        result = call_service
        expect(result.keys).to contain_exactly(:success, :booking, :error)
      end

      it "error is nil on success" do
        result = call_service
        expect(result[:error]).to be_nil
      end

      it "booking is nil on failure" do
        result = call_service(service_ids: [])
        expect(result[:booking]).to be_nil
      end
    end

    context "customer_email optional" do
      it "works without customer_email" do
        result = call_service
        expect(result[:success]).to be true
        expect(result[:booking].customer_email).to be_nil
      end

      it "accepts customer_email in params" do
        params = customer_params.merge(customer_email: "customer@example.com")
        result = call_service(customer_params: params)
        expect(result[:success]).to be true
        expect(result[:booking].customer_email).to eq("customer@example.com")
      end
    end

    context "with customer_notes" do
      it "accepts customer_notes in params" do
        params = customer_params.merge(notes: "Special request: allergic to lavender")
        result = call_service(customer_params: params)
        expect(result[:success]).to be true
        expect(result[:booking].notes).to eq("Special request: allergic to lavender")
      end
    end
  end
end

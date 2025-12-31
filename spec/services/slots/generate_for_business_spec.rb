require "rails_helper"

RSpec.describe Slots::GenerateForBusiness do
  let(:business) { create(:business, capacity: 3) }

  describe "#call" do
    before do
      # Set operating hours: Mon-Fri 9:00-12:00 (3 hours = 12 slots of 15min each)
      # Saturday closed, Sunday closed
      business.update!(
        operating_hours: {
          "monday" => { "open" => "09:00", "close" => "12:00", "closed" => false, "breaks" => [] },
          "tuesday" => { "open" => "09:00", "close" => "12:00", "closed" => false, "breaks" => [] },
          "wednesday" => { "open" => "09:00", "close" => "12:00", "closed" => false, "breaks" => [] },
          "thursday" => { "open" => "09:00", "close" => "12:00", "closed" => false, "breaks" => [] },
          "friday" => { "open" => "09:00", "close" => "12:00", "closed" => false, "breaks" => [] },
          "saturday" => { "closed" => true },
          "sunday" => { "closed" => true }
        }
      )
    end

    context "generating slots for a specific date" do
      it "creates 15-minute interval slots within operating hours" do
        # Use a future Monday
        date = Date.new(2025, 12, 29) # Monday

        service = described_class.new(business: business, date: date)
        result = service.call

        expect(result[:success]).to be true
        expect(result[:slots_created]).to eq(12) # 9:00-12:00 = 3 hours = 12 slots

        # Verify slots were created
        slots = business.slots.for_date(date).order(:start_time)
        expect(slots.count).to eq(12)

        # Check first slot
        first_slot = slots.first
        expect(first_slot.start_time).to eq(Time.zone.parse("2025-12-29 09:00"))
        expect(first_slot.end_time).to eq(Time.zone.parse("2025-12-29 09:15"))
        expect(first_slot.capacity).to eq(3)
        expect(first_slot.original_capacity).to eq(3)

        # Check last slot
        last_slot = slots.last
        expect(last_slot.start_time).to eq(Time.zone.parse("2025-12-29 11:45"))
        expect(last_slot.end_time).to eq(Time.zone.parse("2025-12-29 12:00"))
      end

      it "skips closed days" do
        # Saturday is closed
        date = Date.new(2025, 12, 27) # Saturday

        service = described_class.new(business: business, date: date)
        result = service.call

        expect(result[:success]).to be true
        expect(result[:slots_created]).to eq(0)
        expect(business.slots.for_date(date).count).to eq(0)
      end

      it "sets capacity from business capacity" do
        business.update!(capacity: 5)
        date = Date.new(2025, 12, 29) # Monday

        service = described_class.new(business: business, date: date)
        service.call

        slots = business.slots.for_date(date)
        expect(slots.all? { |slot| slot.capacity == 5 }).to be true
        expect(slots.all? { |slot| slot.original_capacity == 5 }).to be true
      end

      it "is idempotent - does not create duplicate slots" do
        date = Date.new(2025, 12, 29) # Monday

        service1 = described_class.new(business: business, date: date)
        result1 = service1.call

        expect(result1[:success]).to be true
        expect(result1[:slots_created]).to eq(12)

        # Run again
        service2 = described_class.new(business: business, date: date)
        result2 = service2.call

        expect(result2[:success]).to be true
        expect(result2[:slots_created]).to eq(0) # No new slots created
        expect(business.slots.for_date(date).count).to eq(12) # Still only 12 slots
      end

      it "handles business with no operating hours" do
        business.update!(operating_hours: {})
        date = Date.new(2025, 12, 29)

        service = described_class.new(business: business, date: date)
        result = service.call

        expect(result[:success]).to be true
        expect(result[:slots_created]).to eq(0)
      end

      it "correctly sets the date field for each slot" do
        date = Date.new(2025, 12, 29) # Monday

        service = described_class.new(business: business, date: date)
        service.call

        slots = business.slots.for_date(date)
        expect(slots.all? { |slot| slot.date == date }).to be true
      end
    end

    context "generating slots for multiple days" do
      it "generates slots for 7 days ahead when no date specified" do
        service = described_class.new(business: business)
        result = service.call

        expect(result[:success]).to be true

        # Count slots created for next 7 days
        # Depends on which days are open in the next 7 days
        total_slots = business.slots.count
        expect(total_slots).to be > 0
      end

      it "returns message with count of slots created" do
        date = Date.new(2025, 12, 29) # Monday

        service = described_class.new(business: business, date: date)
        result = service.call

        expect(result[:message]).to include("12 slots created")
      end
    end

    context "handling breaks in operating hours" do
      before do
        business.update!(
          operating_hours: {
            "monday" => {
              "open" => "09:00",
              "close" => "15:00",
              "closed" => false,
              "breaks" => [ { "start" => "12:00", "end" => "13:00" } ]
            },
            "tuesday" => { "closed" => true },
            "wednesday" => { "closed" => true },
            "thursday" => { "closed" => true },
            "friday" => { "closed" => true },
            "saturday" => { "closed" => true },
            "sunday" => { "closed" => true }
          }
        )
      end

      it "generates slots including break times (slots exist but can be marked unavailable separately)" do
        date = Date.new(2025, 12, 29) # Monday

        service = described_class.new(business: business, date: date)
        result = service.call

        # 9:00-15:00 = 6 hours = 24 slots (including break time)
        # We generate ALL slots, break handling is done at availability check time
        expect(result[:slots_created]).to eq(24)

        # Verify break time slots exist
        break_slot = business.slots.for_date(date).find_by(start_time: Time.zone.parse("2025-12-29 12:00"))
        expect(break_slot).to be_present
      end
    end
  end
end

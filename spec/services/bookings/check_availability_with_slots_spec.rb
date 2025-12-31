require "rails_helper"

RSpec.describe Bookings::CheckAvailability, type: :service do
  let(:business) { create(:business, capacity: 3) }
  let(:service_30min) { create(:service, business: business, duration_minutes: 30) }
  let(:service_60min) { create(:service, business: business, duration_minutes: 60) }
  let(:date) { Date.new(2025, 12, 26) } # Friday

  before do
    # Set up operating hours: 9am-6pm on Friday
    business.update!(
      operating_hours: {
        "friday" => { "open" => "09:00", "close" => "18:00", "closed" => false, "breaks" => [] }
      }
    )

    # Generate slots for the test date
    Slots::GenerateForBusiness.new(business: business, date: date).call
  end

  describe "#call - slot-based availability" do
    context "when all slots are available" do
      it "returns available start times for the service" do
        result = described_class.new(
          business: business,
          service: service_30min,
          date: date
        ).call

        expect(result).to be_an(Array)
        expect(result).not_to be_empty

        # Should include times from 9:00am onwards
        expect(result).to include(Time.zone.parse("2025-12-26 09:00"))
        expect(result).to include(Time.zone.parse("2025-12-26 09:15"))
      end

      it "only returns times where ALL consecutive slots have capacity" do
        # For 30min service (2 slots), need 2 consecutive slots with capacity
        result = described_class.new(
          business: business,
          service: service_30min,
          date: date
        ).call

        # Verify all returned times can accommodate the service
        result.each do |start_time|
          slot1 = business.slots.find_by(start_time: start_time)
          slot2 = business.slots.find_by(start_time: start_time + 15.minutes)

          expect(slot1.capacity).to be > 0
          expect(slot2.capacity).to be > 0
        end
      end

      it "handles longer services (60 min = 4 slots)" do
        result = described_class.new(
          business: business,
          service: service_60min,
          date: date
        ).call

        expect(result).to be_an(Array)
        expect(result).not_to be_empty

        # Verify start times can fit 60min service
        result.each do |start_time|
          required_slots = 4
          slots = business.slots.where(
            "start_time >= ? AND start_time < ?",
            start_time,
            start_time + 60.minutes
          ).order(:start_time)

          expect(slots.count).to eq(required_slots)
          expect(slots.all? { |s| s.capacity > 0 }).to be true
        end
      end
    end

    context "when some slots have no capacity" do
      before do
        # Make 10:00-10:15 slot unavailable
        slot = business.slots.find_by(start_time: Time.zone.parse("2025-12-26 10:00"))
        slot.update!(capacity: 0)
      end

      it "excludes start times that include unavailable slots" do
        result = described_class.new(
          business: business,
          service: service_30min, # Needs 2 consecutive 15-min slots
          date: date
        ).call

        # Should NOT include 10:00 (first slot unavailable)
        expect(result).not_to include(Time.zone.parse("2025-12-26 10:00"))

        # Should NOT include 9:45 (would need unavailable 10:00-10:15 slot)
        expect(result).not_to include(Time.zone.parse("2025-12-26 09:45"))

        # Should still include earlier times that don't need the unavailable slot
        expect(result).to include(Time.zone.parse("2025-12-26 09:00"))
        expect(result).to include(Time.zone.parse("2025-12-26 09:30"))
      end

      it "also excludes times where service would overlap unavailable slot" do
        # 10:00-10:15 is unavailable
        # For 30min service starting at 9:45, it would need 9:45-10:00 AND 10:00-10:15
        result = described_class.new(
          business: business,
          service: service_30min,
          date: date
        ).call

        # Should NOT include 9:45 (would need unavailable 10:00-10:15 slot)
        expect(result).not_to include(Time.zone.parse("2025-12-26 09:45"))

        # Should include earlier times that don't overlap with unavailable slot
        expect(result).to include(Time.zone.parse("2025-12-26 09:00"))
        expect(result).to include(Time.zone.parse("2025-12-26 09:15"))
        expect(result).to include(Time.zone.parse("2025-12-26 09:30"))

        # Should include times after the unavailable slot
        expect(result).to include(Time.zone.parse("2025-12-26 10:15"))
      end
    end

    context "when slots are partially filled but still have capacity" do
      before do
        # Reduce capacity but keep some available
        business.slots.where(
          "start_time >= ? AND start_time < ?",
          Time.zone.parse("2025-12-26 10:00"),
          Time.zone.parse("2025-12-26 11:00")
        ).update_all(capacity: 1) # Still available but limited
      end

      it "includes times with reduced capacity" do
        result = described_class.new(
          business: business,
          service: service_30min,
          date: date
        ).call

        # Should still include 10:00 (capacity > 0)
        expect(result).to include(Time.zone.parse("2025-12-26 10:00"))
      end
    end

    context "when business is closed on the date" do
      let(:sunday) { Date.new(2025, 12, 28) } # Sunday

      before do
        business.update!(
          operating_hours: {
            "sunday" => { "closed" => true }
          }
        )
      end

      it "returns empty array for closed days" do
        result = described_class.new(
          business: business,
          service: service_30min,
          date: sunday
        ).call

        expect(result).to eq([])
      end
    end

    context "when no slots exist for the date" do
      let(:future_date) { Date.new(2026, 1, 1) }

      it "returns empty array" do
        result = described_class.new(
          business: business,
          service: service_30min,
          date: future_date
        ).call

        expect(result).to eq([])
      end
    end

    context "end of day handling" do
      it "does not include times too close to closing where service won't fit" do
        # 60min service ending at or after 6pm should not be available
        result = described_class.new(
          business: business,
          service: service_60min, # 60 minutes
          date: date
        ).call

        # Last available time should be 5:00pm (ends at 6:00pm)
        expect(result).to include(Time.zone.parse("2025-12-26 17:00"))

        # Should NOT include 5:15pm or later (would end after 6pm)
        expect(result).not_to include(Time.zone.parse("2025-12-26 17:15"))
        expect(result).not_to include(Time.zone.parse("2025-12-26 17:30"))
      end
    end

    context "with gaps in slot sequence" do
      before do
        # Delete a slot in the middle to create a gap
        slot = business.slots.find_by(start_time: Time.zone.parse("2025-12-26 10:15"))
        slot.destroy
      end

      it "excludes start times that would span a gap" do
        result = described_class.new(
          business: business,
          service: service_30min,
          date: date
        ).call

        # Should NOT include 10:00 (needs 10:00-10:15 and 10:15-10:30, but 10:15-10:30 doesn't exist)
        expect(result).not_to include(Time.zone.parse("2025-12-26 10:00"))

        # Should NOT include 10:15 (doesn't exist)
        expect(result).not_to include(Time.zone.parse("2025-12-26 10:15"))
      end
    end

    context "returns chronological order" do
      it "returns available times in ascending order" do
        result = described_class.new(
          business: business,
          service: service_30min,
          date: date
        ).call

        expect(result).to eq(result.sort)
      end
    end

    context "with break times" do
      before do
        business.update!(
          operating_hours: {
            "friday" => {
              "open" => "09:00",
              "close" => "18:00",
              "closed" => false,
              "breaks" => [ { "start" => "12:00", "end" => "13:00" } ]
            }
          }
        )

        # Regenerate slots with break
        business.slots.for_date(date).delete_all
        Slots::GenerateForBusiness.new(business: business, date: date).call
      end

      it "includes times during break (slots exist, availability checking is separate)" do
        result = described_class.new(
          business: business,
          service: service_30min,
          date: date
        ).call

        # Slots exist during break time (12:00-13:00)
        # Break handling is done at booking creation, not availability check
        expect(result).to include(Time.zone.parse("2025-12-26 12:00"))
      end
    end
  end
end

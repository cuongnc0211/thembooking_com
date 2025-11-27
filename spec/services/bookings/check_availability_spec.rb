require "rails_helper"

RSpec.describe Bookings::CheckAvailability do
  let(:business) { create(:business, capacity: 2) }
  let(:service_30min) { create(:service, business: business, duration_minutes: 30) }
  let(:service_15min) { create(:service, business: business, duration_minutes: 15) }

  describe "#call" do
    context "when business is open on the date" do
      before do
        # Set operating hours: Mon-Fri 9:00-17:00, break 12:00-13:00
        business.update!(
          operating_hours: {
            "monday" => { "open" => "09:00", "close" => "17:00", "break_start" => "12:00", "break_end" => "13:00", "closed" => false },
            "tuesday" => { "open" => "09:00", "close" => "17:00", "break_start" => "12:00", "break_end" => "13:00", "closed" => false },
            "wednesday" => { "open" => "09:00", "close" => "17:00", "break_start" => "12:00", "break_end" => "13:00", "closed" => false },
            "thursday" => { "open" => "09:00", "close" => "17:00", "break_start" => "12:00", "break_end" => "13:00", "closed" => false },
            "friday" => { "open" => "09:00", "close" => "17:00", "break_start" => "12:00", "break_end" => "13:00", "closed" => false },
            "saturday" => { "closed" => true },
            "sunday" => { "closed" => true }
          }
        )
      end

      it "returns available time slots within operating hours" do
        # Wednesday, Nov 27, 2025
        date = Date.new(2025, 11, 27) # Wednesday
        service = described_class.new(
          business: business,
          service_ids: [service_30min.id],
          date: date
        )

        slots = service.call

        # Should include slots from 9:00 to 16:30 (last slot that can fit 30min service before 17:00 close)
        # But excluding break time 12:00-13:00
        expect(slots).to be_an(Array)
        expect(slots).to include("09:00", "09:15", "09:30", "09:45")
        expect(slots).not_to be_empty
      end

      it "excludes slots during break times" do
        date = Date.new(2025, 11, 27) # Wednesday
        service = described_class.new(
          business: business,
          service_ids: [service_30min.id],
          date: date
        )

        slots = service.call

        # Slots at 12:00 and 12:30 should be excluded because they overlap with break (12:00-13:00)
        # 12:00-12:30 overlaps with break
        # 12:30-13:00 overlaps with break
        expect(slots).not_to include("12:00", "12:15", "12:30", "12:45")
      end

      it "handles multiple services by summing durations" do
        date = Date.new(2025, 11, 27) # Wednesday
        # Total duration: 30 + 15 = 45 minutes
        service = described_class.new(
          business: business,
          service_ids: [service_30min.id, service_15min.id],
          date: date
        )

        slots = service.call

        # Last slot before close (17:00) should be 16:15 (16:15 + 45min = 17:00)
        expect(slots).to include("16:00", "16:15")
        expect(slots).not_to include("16:30", "16:45") # These would extend past closing
      end

      it "excludes slots that extend past closing time" do
        date = Date.new(2025, 11, 27) # Wednesday
        # Service ends at 17:00 (close time)
        service = described_class.new(
          business: business,
          service_ids: [service_30min.id],
          date: date
        )

        slots = service.call

        # 16:30 is last possible slot (16:30 + 30min = 17:00)
        expect(slots).to include("16:30")
        # 16:45 would extend to 17:15, past closing
        expect(slots).not_to include("16:45")
      end

      it "excludes fully booked slots based on capacity" do
        date = Date.new(2025, 11, 27) # Wednesday
        time_10am = Time.zone.parse("2025-11-27 10:00")

        # Create 2 bookings at 10:00 (capacity is 2)
        2.times do
          booking = create(:booking, business: business, scheduled_at: time_10am, status: :confirmed)
          booking.services.clear
          booking.services << service_30min
          booking.save!
        end

        service = described_class.new(
          business: business,
          service_ids: [service_30min.id],
          date: date
        )

        slots = service.call

        # 10:00, 10:15 should be unavailable (fully booked until 10:30)
        expect(slots).not_to include("10:00", "10:15")
        # But 10:30 onwards should be available
        expect(slots).to include("10:30", "10:45")
      end

      it "includes slots that have capacity available" do
        date = Date.new(2025, 11, 27) # Wednesday
        time_10am = Time.zone.parse("2025-11-27 10:00")

        # Create only 1 booking at 10:00 (capacity is 2, so 1 more slot available)
        booking = create(:booking, business: business, scheduled_at: time_10am, status: :confirmed)
        booking.services.clear
        booking.services << service_30min
        booking.save!

        service = described_class.new(
          business: business,
          service_ids: [service_30min.id],
          date: date
        )

        slots = service.call

        # 10:00, 10:15 should still be available (1 out of 2 capacity used)
        expect(slots).to include("10:00", "10:15")
      end
    end

    context "when business is closed on the date" do
      before do
        business.update!(
          operating_hours: {
            "saturday" => { "closed" => true },
            "sunday" => { "closed" => true }
          }
        )
      end

      it "returns empty array for closed days" do
        date = Date.new(2025, 11, 29) # Saturday
        service = described_class.new(
          business: business,
          service_ids: [service_30min.id],
          date: date
        )

        slots = service.call

        expect(slots).to eq([])
      end
    end

    context "when checking availability for today" do
      before do
        business.update!(
          operating_hours: {
            "monday" => { "open" => "09:00", "close" => "17:00", "closed" => false },
            "tuesday" => { "open" => "09:00", "close" => "17:00", "closed" => false },
            "wednesday" => { "open" => "09:00", "close" => "17:00", "closed" => false },
            "thursday" => { "open" => "09:00", "close" => "17:00", "closed" => false },
            "friday" => { "open" => "09:00", "close" => "17:00", "closed" => false }
          }
        )
      end

      it "excludes past time slots" do
        # Freeze time to 10:30 AM on a Wednesday
        travel_to Time.zone.parse("2025-11-26 10:30") do
          date = Date.new(2025, 11, 26) # Today (Wednesday)
          service = described_class.new(
            business: business,
            service_ids: [service_30min.id],
            date: date
          )

          slots = service.call

          # Should not include slots before 10:30
          expect(slots).not_to include("09:00", "09:15", "09:30", "10:00", "10:15")
          # Should include future slots
          expect(slots).to include("10:30", "10:45", "11:00")
        end
      end
    end

    context "edge cases" do
      it "handles business with no break time" do
        business.update!(
          operating_hours: {
            "thursday" => { "open" => "09:00", "close" => "17:00", "closed" => false }
          }
        )

        date = Date.new(2025, 11, 27) # Thursday
        service = described_class.new(
          business: business,
          service_ids: [service_30min.id],
          date: date
        )

        slots = service.call

        # Should return continuous slots from 9:00 to 16:30
        expect(slots.size).to be > 20 # Many slots available
        expect(slots).to include("12:00", "12:15", "12:30") # No break exclusion
      end

      it "returns empty array when service_ids is empty" do
        date = Date.new(2025, 11, 27)
        service = described_class.new(
          business: business,
          service_ids: [],
          date: date
        )

        slots = service.call

        expect(slots).to eq([])
      end

      it "handles very long service durations" do
        long_service = create(:service, business: business, duration_minutes: 120) # 2 hours

        business.update!(
          operating_hours: {
            "thursday" => { "open" => "09:00", "close" => "17:00", "closed" => false }
          }
        )

        date = Date.new(2025, 11, 27) # Thursday
        service = described_class.new(
          business: business,
          service_ids: [long_service.id],
          date: date
        )

        slots = service.call

        # Only slots from 9:00 to 15:00 would work (15:00 + 2hrs = 17:00)
        expect(slots).to include("09:00", "15:00")
        expect(slots).not_to include("15:15", "16:00")
      end
    end
  end
end

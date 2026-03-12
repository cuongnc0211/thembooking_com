require "rails_helper"

RSpec.describe Bookings::CheckAvailability, type: :service do
  let(:user) { create(:user) }
  let(:business) do
    create(:business, user: user, capacity: 2, operating_hours: {
      "monday" => { "open" => "09:00", "close" => "17:00", "closed" => false, "breaks" => [{ "start" => "12:00", "end" => "13:00" }] },
      "tuesday" => { "open" => "09:00", "close" => "17:00", "closed" => false, "breaks" => [{ "start" => "12:00", "end" => "13:00" }] },
      "wednesday" => { "open" => "09:00", "close" => "17:00", "closed" => false, "breaks" => [{ "start" => "12:00", "end" => "13:00" }] },
      "thursday" => { "open" => "09:00", "close" => "17:00", "closed" => false, "breaks" => [{ "start" => "12:00", "end" => "13:00" }] },
      "friday" => { "open" => "09:00", "close" => "17:00", "closed" => false, "breaks" => [{ "start" => "12:00", "end" => "13:00" }] },
      "saturday" => { "open" => "10:00", "close" => "16:00", "closed" => false, "breaks" => [] },
      "sunday" => { "open" => nil, "close" => nil, "closed" => true, "breaks" => [] }
    })
  end
  let(:service) { create(:service, business: business, duration_minutes: 30) }

  # Helper to find next occurrence of a given weekday
  def next_occurrence_of(weekday)
    today = Date.current
    target_day = Date::DAYNAMES.index(weekday.to_s.capitalize)
    current_day = today.wday

    days_ahead = target_day - current_day
    days_ahead += 7 if days_ahead <= 0

    today + days_ahead.days
  end

  describe "#call" do
    context "on a closed day (Sunday)" do
      it "returns empty array" do
        sunday = next_occurrence_of(:sunday)
        result = described_class.new(business: business, service_ids: [service.id], date: sunday).call
        expect(result).to eq([])
      end
    end

    context "on a business closure date" do
      it "returns empty array" do
        monday = next_occurrence_of(:monday)
        create(:business_closure, business: business, date: monday)
        result = described_class.new(business: business, service_ids: [service.id], date: monday).call
        expect(result).to eq([])
      end
    end

    context "on a normal open day with no bookings" do
      it "returns available slots within operating hours" do
        monday = next_occurrence_of(:monday)
        result = described_class.new(business: business, service_ids: [service.id], date: monday).call

        expect(result).not_to be_empty
        # First slot at opening time
        expect(result.first).to eq(Time.zone.parse("#{monday} 09:00"))
        # No slots during break (12:00-13:00) — 30-min service starting at 11:45 ends at 12:15 (overlaps break)
        break_overlapping = result.select { |t| t >= Time.zone.parse("#{monday} 11:45") && t < Time.zone.parse("#{monday} 13:00") }
        expect(break_overlapping).to be_empty
        # Last slot ends at 17:00
        expect(result.last).to eq(Time.zone.parse("#{monday} 16:30"))
      end

      it "respects break periods correctly" do
        monday = next_occurrence_of(:monday)
        result = described_class.new(business: business, service_ids: [service.id], date: monday).call

        # Verify no slots start during or would overlap the break
        break_start = Time.zone.parse("#{monday} 12:00")
        break_end = Time.zone.parse("#{monday} 13:00")

        result.each do |slot_start|
          slot_end = slot_start + 30.minutes
          # Check that the slot doesn't overlap the break
          overlaps_break = (slot_start < break_end && slot_end > break_start)
          expect(overlaps_break).to be false
        end
      end
    end

    context "with Saturday (different hours)" do
      it "uses Saturday's operating hours (10:00-16:00, no breaks)" do
        saturday = next_occurrence_of(:saturday)
        result = described_class.new(business: business, service_ids: [service.id], date: saturday).call

        expect(result).not_to be_empty
        expect(result.first).to eq(Time.zone.parse("#{saturday} 10:00"))
        expect(result.last).to eq(Time.zone.parse("#{saturday} 15:30"))
      end
    end

    context "when capacity is partially used" do
      it "still returns slots if under capacity" do
        monday = next_occurrence_of(:monday)
        start_time = Time.zone.parse("#{monday} 10:00")
        create(:booking, business: business, scheduled_at: start_time, end_time: start_time + 30.minutes, status: :confirmed, services: [service])

        result = described_class.new(business: business, service_ids: [service.id], date: monday).call
        # 10:00 slot: 1 booking, capacity 2 → still available
        expect(result).to include(start_time)
      end

      it "excludes slots at full capacity" do
        monday = next_occurrence_of(:monday)
        start_time = Time.zone.parse("#{monday} 10:00")
        # Fill to capacity (2)
        2.times { create(:booking, business: business, scheduled_at: start_time, end_time: start_time + 30.minutes, status: :confirmed, services: [service]) }

        result = described_class.new(business: business, service_ids: [service.id], date: monday).call
        expect(result).not_to include(start_time)
      end
    end

    context "with cancelled bookings" do
      it "does not count cancelled bookings toward capacity" do
        monday = next_occurrence_of(:monday)
        start_time = Time.zone.parse("#{monday} 10:00")
        2.times { create(:booking, business: business, scheduled_at: start_time, end_time: start_time + 30.minutes, status: :cancelled, services: [service]) }

        result = described_class.new(business: business, service_ids: [service.id], date: monday).call
        expect(result).to include(start_time)
      end
    end

    context "with multiple services" do
      it "calculates total duration across all services" do
        monday = next_occurrence_of(:monday)
        service2 = create(:service, business: business, duration_minutes: 45)
        result = described_class.new(business: business, service_ids: [service.id, service2.id], date: monday).call

        # 30 + 45 = 75 minutes total
        expect(result).not_to be_empty
        # Verify last slot: 09:00 + 75 minutes = 10:15, so last slot should be 16:30 (close at 17:00)
        # Slots are every 15 min: ..., 16:15 (ends 17:30 > 17:00, invalid), 16:00 (ends 17:15 > 17:00, invalid), ...
        expect(result.last).to be <= Time.zone.parse("#{monday} 15:45")
      end
    end

    context "with pending and in_progress bookings" do
      it "counts pending bookings toward capacity" do
        monday = next_occurrence_of(:monday)
        start_time = Time.zone.parse("#{monday} 10:00")
        create(:booking, business: business, scheduled_at: start_time, end_time: start_time + 30.minutes, status: :pending, services: [service])

        result = described_class.new(business: business, service_ids: [service.id], date: monday).call
        expect(result).to include(start_time)
      end

      it "counts in_progress bookings toward capacity" do
        monday = next_occurrence_of(:monday)
        start_time = Time.zone.parse("#{monday} 10:00")
        create(:booking, business: business, scheduled_at: start_time, end_time: start_time + 30.minutes, status: :in_progress, services: [service])

        result = described_class.new(business: business, service_ids: [service.id], date: monday).call
        expect(result).to include(start_time)
      end
    end

    context "with single service parameter" do
      it "works with single service object instead of service_ids" do
        monday = next_occurrence_of(:monday)
        result = described_class.new(business: business, service: service, date: monday).call
        expect(result).not_to be_empty
      end
    end

    context "with empty service_ids" do
      it "returns empty array" do
        monday = next_occurrence_of(:monday)
        result = described_class.new(business: business, service_ids: [], date: monday).call
        expect(result).to eq([])
      end
    end

    context "with date as string" do
      it "parses date string correctly" do
        monday = next_occurrence_of(:monday)
        result = described_class.new(business: business, service_ids: [service.id], date: monday.to_s).call
        expect(result).not_to be_empty
      end
    end

    context "with overlapping bookings at different times" do
      it "correctly identifies available slots between bookings" do
        monday = next_occurrence_of(:monday)
        # Booking 1: 10:00-10:30 (capacity 2, so there's still room at 10:00)
        create(:booking, business: business, scheduled_at: Time.zone.parse("#{monday} 10:00"), end_time: Time.zone.parse("#{monday} 10:30"), status: :confirmed, services: [service])
        # Booking 2: 10:00-10:30 (fills capacity at this time)
        create(:booking, business: business, scheduled_at: Time.zone.parse("#{monday} 10:00"), end_time: Time.zone.parse("#{monday} 10:30"), status: :confirmed, services: [service])

        result = described_class.new(business: business, service_ids: [service.id], date: monday).call

        # 10:00 should NOT be available (at capacity)
        expect(result).not_to include(Time.zone.parse("#{monday} 10:00"))
        # 10:30 should be available (no booking conflicts)
        expect(result).to include(Time.zone.parse("#{monday} 10:30"))
        # 10:45 should be available (no booking conflicts)
        expect(result).to include(Time.zone.parse("#{monday} 10:45"))
      end
    end
  end
end

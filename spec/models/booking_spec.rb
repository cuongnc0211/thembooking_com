require "rails_helper"

RSpec.describe Booking, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:business) }
    it { is_expected.to have_many(:booking_services).dependent(:destroy) }
    it { is_expected.to have_many(:services).through(:booking_services) }
  end

  describe "validations" do
    subject { build(:booking) }

    it { is_expected.to validate_presence_of(:customer_name) }
    it { is_expected.to validate_presence_of(:customer_phone) }
    it { is_expected.to validate_presence_of(:scheduled_at) }

    describe "customer_phone format" do
      it "accepts valid Vietnam phone numbers" do
        booking = build(:booking, customer_phone: "0912345678")
        expect(booking).to be_valid
      end

      it "rejects phone numbers not starting with 0" do
        booking = build(:booking, customer_phone: "9123456789")
        booking.valid?
        expect(booking.errors[:customer_phone]).to include("must be a valid Vietnam phone number (10 digits starting with 0)")
      end

      it "rejects phone numbers with less than 10 digits" do
        booking = build(:booking, customer_phone: "091234567")
        booking.valid?
        expect(booking.errors[:customer_phone]).to include("must be a valid Vietnam phone number (10 digits starting with 0)")
      end

      it "rejects phone numbers with more than 10 digits" do
        booking = build(:booking, customer_phone: "09123456789")
        booking.valid?
        expect(booking.errors[:customer_phone]).to include("must be a valid Vietnam phone number (10 digits starting with 0)")
      end
    end

    describe "customer_email format" do
      it "accepts valid email addresses" do
        booking = build(:booking, customer_email: "customer@example.com")
        expect(booking).to be_valid
      end

      it "accepts nil email (optional field)" do
        booking = build(:booking, customer_email: nil)
        expect(booking).to be_valid
      end

      it "rejects invalid email format" do
        booking = build(:booking, customer_email: "invalid-email")
        booking.valid?
        expect(booking.errors[:customer_email]).to include("is not a valid email address")
      end
    end

    describe "scheduled_at validations" do
      it "rejects past scheduled times" do
        booking = build(:booking, scheduled_at: 1.hour.ago)
        booking.valid?
        expect(booking.errors[:scheduled_at]).to include("must be in the future")
      end

      it "accepts future scheduled times" do
        booking = build(:booking, scheduled_at: 1.hour.from_now)
        expect(booking).to be_valid
      end
    end

    describe "must have at least one service" do
      it "is invalid without any services" do
        booking = build(:booking)
        # Clear services added by factory
        booking.services.clear
        booking.valid?
        expect(booking.errors[:services]).to include("must have at least one service")
      end

      it "is valid with at least one service" do
        booking = build(:booking)
        # Factory already adds a service
        expect(booking).to be_valid
      end
    end
  end

  describe "enums" do
    it "defines status enum" do
      expect(Booking.statuses.keys).to match_array(%w[pending confirmed in_progress completed cancelled no_show])
    end

    it "defines source enum" do
      expect(Booking.sources.keys).to match_array(%w[online walk_in])
    end

    it "defaults status to pending" do
      booking = Booking.new
      expect(booking.status).to eq("pending")
    end

    it "defaults source to online" do
      booking = Booking.new
      expect(booking.source).to eq("online")
    end
  end

  describe "scopes" do
    let(:business) { create(:business) }
    let(:service) { create(:service, business: business) }

    let!(:confirmed_booking) do
      booking = create(:booking, business: business, status: :confirmed, scheduled_at: 1.hour.from_now)
      booking.services.clear
      booking.services << service
      booking
    end

    let!(:in_progress_booking) do
      booking = create(:booking, business: business, status: :in_progress, scheduled_at: 1.hour.from_now)
      booking.services.clear
      booking.services << service
      booking
    end

    let!(:completed_booking) do
      booking = create(:booking, business: business, status: :completed, scheduled_at: 1.hour.from_now)
      booking.services.clear
      booking.services << service
      booking
    end

    let!(:cancelled_booking) do
      booking = create(:booking, business: business, status: :cancelled, scheduled_at: 1.hour.from_now)
      booking.services.clear
      booking.services << service
      booking
    end

    describe ".active" do
      it "returns confirmed and in_progress bookings" do
        expect(Booking.active).to contain_exactly(confirmed_booking, in_progress_booking)
      end
    end

    describe ".for_date" do
      it "returns bookings scheduled on the given date" do
        today_booking = create(:booking, business: business, scheduled_at: Time.zone.now.beginning_of_day + 10.hours)
        tomorrow_booking = create(:booking, business: business, scheduled_at: 1.day.from_now.beginning_of_day + 10.hours)

        expect(Booking.for_date(Date.today)).to include(today_booking)
        expect(Booking.for_date(Date.today)).not_to include(tomorrow_booking)
      end
    end

    describe ".overlapping" do
      let!(:booking_10_to_11) do
        booking = create(:booking, business: business, scheduled_at: Time.zone.parse("2025-12-26 10:00"))
        booking.services.clear
        service_60min = create(:service, business: business, duration_minutes: 60)
        booking.services << service_60min
        booking
      end

      let!(:booking_11_to_12) do
        booking = create(:booking, business: business, scheduled_at: Time.zone.parse("2025-12-26 11:00"))
        booking.services.clear
        service_60min = create(:service, business: business, duration_minutes: 60)
        booking.services << service_60min
        booking
      end

      it "finds bookings that overlap with the given time range" do
        # Check overlap with 10:30-11:30 (should overlap with booking_10_to_11)
        start_time = Time.zone.parse("2025-12-26 10:30")
        end_time = Time.zone.parse("2025-12-26 11:30")

        overlapping = Booking.overlapping(start_time, end_time)

        expect(overlapping).to include(booking_10_to_11)
        expect(overlapping).to include(booking_11_to_12)
      end

      it "excludes bookings that don't overlap" do
        # Check overlap with 9:00-10:00 (should not overlap with either booking)
        start_time = Time.zone.parse("2025-12-26 09:00")
        end_time = Time.zone.parse("2025-12-26 10:00")

        overlapping = Booking.overlapping(start_time, end_time)

        expect(overlapping).not_to include(booking_10_to_11)
        expect(overlapping).not_to include(booking_11_to_12)
      end
    end
  end

  describe "#total_duration_minutes" do
    it "returns sum of all service durations" do
      business = create(:business)
      booking = create(:booking, business: business)
      # Clear the default service added by factory
      booking.services.clear

      service1 = create(:service, business: business, name: "Haircut", duration_minutes: 30)
      service2 = create(:service, business: business, name: "Beard Trim", duration_minutes: 15)

      booking.services << [service1, service2]

      expect(booking.total_duration_minutes).to eq(45)
    end

    it "returns 0 when no services are associated" do
      booking = create(:booking)
      booking.services.clear

      expect(booking.total_duration_minutes).to eq(0)
    end
  end

  describe "#end_time" do
    it "returns scheduled_at plus total duration" do
      business = create(:business)
      future_time = Time.zone.parse("2025-12-26 10:00") # Use a future date
      booking = create(:booking, business: business, scheduled_at: future_time)
      # Clear default service
      booking.services.clear

      service = create(:service, business: business, name: "Long Service", duration_minutes: 45)
      booking.services << service

      expect(booking.end_time).to eq(future_time + 45.minutes)
    end
  end
end

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
end

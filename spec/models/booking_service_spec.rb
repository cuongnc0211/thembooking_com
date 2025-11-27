require "rails_helper"

RSpec.describe BookingService, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:booking) }
    it { is_expected.to belong_to(:service) }
  end

  describe "validations" do
    subject { build(:booking_service) }

    it "ensures unique booking and service combination" do
      booking = create(:booking)
      service = create(:service, business: booking.business)

      # Create first booking_service
      BookingService.create!(booking: booking, service: service)

      # Attempt to create duplicate
      duplicate = BookingService.new(booking: booking, service: service)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:service_id]).to include("has already been added to this booking")
    end
  end
end

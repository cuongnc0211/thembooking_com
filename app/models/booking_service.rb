class BookingService < ApplicationRecord
  belongs_to :booking
  belongs_to :service

  validates :service_id, uniqueness: {
    scope: :booking_id,
    message: "has already been added to this booking"
  }
end

FactoryBot.define do
  factory :booking_service do
    booking
    service { association :service, business: booking.business }
  end
end

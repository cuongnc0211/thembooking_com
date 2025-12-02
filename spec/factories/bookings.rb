FactoryBot.define do
  factory :booking do
    business
    customer_name { Faker::Name.name }
    customer_email { Faker::Internet.email }
    customer_phone { "09#{Faker::Number.number(digits: 8)}" } # Vietnam phone format
    scheduled_at { 1.day.from_now.change(hour: 10, min: 0) }
    status { :pending }
    source { :online }
    notes { Faker::Lorem.sentence }
    started_at { nil }
    completed_at { nil }

    # Create at least one service association after building
    after(:build) do |booking|
      if booking.services.empty?
        booking.services << build(:service, business: booking.business)
      end
    end

    trait :with_multiple_services do
      after(:build) do |booking|
        booking.services.clear
        booking.services << build(:service, business: booking.business, duration_minutes: 30)
        booking.services << build(:service, business: booking.business, duration_minutes: 15)
      end
    end

    trait :confirmed do
      status { :confirmed }
    end

    trait :in_progress do
      status { :in_progress }
      started_at { Time.current }
    end

    trait :completed do
      status { :completed }
      started_at { 1.hour.ago }
      completed_at { Time.current }
    end

    trait :cancelled do
      status { :cancelled }
    end

    trait :walk_in do
      source { :walk_in }
    end

    trait :skip_validations do
      to_create { |instance| instance.save(validate: false) }
    end
  end
end

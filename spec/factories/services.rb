FactoryBot.define do
  factory :service do
    association :business
    sequence(:name) { |n| "Service #{n}" }
    description { Faker::Lorem.sentence }
    duration_minutes { 30 }
    price_cents { 8000000 } # 80,000 VND
    currency { "VND" }
    active { true }
    position { 0 }

    trait :inactive do
      active { false }
    end

    trait :short_duration do
      duration_minutes { 15 }
      price_cents { 5000000 } # 50,000 VND
    end

    trait :long_duration do
      duration_minutes { 120 }
      price_cents { 15000000 } # 150,000 VND
    end

    trait :massage do
      name { "Full Body Massage" }
      description { "Relaxing full body massage" }
      duration_minutes { 90 }
      price_cents { 20000000 } # 200,000 VND
    end

    trait :manicure do
      name { "Manicure" }
      description { "Basic manicure service" }
      duration_minutes { 45 }
      price_cents { 10000000 } # 100,000 VND
    end
  end
end

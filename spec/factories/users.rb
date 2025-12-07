FactoryBot.define do
  factory :user do
    email_address { Faker::Internet.email }
    password { "password123" }
    name { Faker::Name.name }
    email_confirmed_at { Time.current }
    onboarding_step { 1 }
    onboarding_completed_at { nil }

    trait :unconfirmed do
      email_confirmed_at { nil }
      email_confirmation_token { SecureRandom.urlsafe_base64(32) }
    end

    trait :onboarding_completed do
      onboarding_step { 5 }
      onboarding_completed_at { Time.current }
      phone { Faker::PhoneNumber.phone_number.gsub(/[^0-9\-\+\s\(\)]/, "") }
    end

    trait :with_business do
      after(:create) do |user|
        create(:business, user: user)
      end
    end

    trait :fully_onboarded do
      onboarding_completed
      after(:create) do |user|
        business = create(:business, user: user)
        create(:service, business: business)
      end
    end
  end
end

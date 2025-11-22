FactoryBot.define do
  factory :user do
    email_address { Faker::Internet.email }
    password { "password123" }
    name { Faker::Name.name }
    email_confirmed_at { Time.current }

    trait :unconfirmed do
      email_confirmed_at { nil }
      email_confirmation_token { SecureRandom.urlsafe_base64(32) }
    end
  end
end

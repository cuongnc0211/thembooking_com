FactoryBot.define do
  factory :staff do
    email_address { Faker::Internet.unique.email }
    name { Faker::Name.name }
    password { "password123" }
    password_confirmation { "password123" }
    role { :super_admin }
    active { true }

    trait :super_admin do
      role { :super_admin }
    end

    trait :developer do
      role { :developer }
    end

    trait :sale do
      role { :sale }
    end

    trait :accountant do
      role { :accountant }
    end
  end
end

FactoryBot.define do
  factory :staff do
    email_address { Faker::Internet.unique.email }
    name { Faker::Name.name }
    password { "password123" }
    password_confirmation { "password123" }
    role { :super_admin }
    active { true }
  end
end

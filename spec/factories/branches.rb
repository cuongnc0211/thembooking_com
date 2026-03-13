FactoryBot.define do
  factory :branch do
    business
    name { "Main Branch" }
    slug { Faker::Internet.slug(glue: "-") }
    capacity { 2 }
    address { Faker::Address.full_address }
    phone { Faker::PhoneNumber.phone_number.gsub(/[^0-9\-\+\s\(\)]/, "") }
    active { true }
    position { 0 }
  end
end

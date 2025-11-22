FactoryBot.define do
  factory :business do
    user
    name { Faker::Company.name }
    slug { Faker::Internet.slug(glue: "-") }
    business_type { :barber }
    capacity { 2 }
    description { Faker::Lorem.paragraph }
    address { Faker::Address.full_address }
    phone { Faker::PhoneNumber.phone_number.gsub(/[^0-9\-\+\s\(\)]/, "") }

    trait :salon do
      business_type { :salon }
    end

    trait :spa do
      business_type { :spa }
    end

    trait :nail do
      business_type { :nail }
    end
  end
end

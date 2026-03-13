FactoryBot.define do
  factory :business do
    user
    name { Faker::Company.name }
    business_type { :barber }
    description { Faker::Lorem.paragraph }

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

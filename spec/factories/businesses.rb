FactoryBot.define do
  factory :business do
    user
    name { Faker::Company.name }
    slug { Faker::Internet.slug(glue: "-") }
    business_type { :barber }
    description { Faker::Lorem.paragraph }
    headline { Faker::Lorem.sentence(word_count: 10) }
    theme_color { "##{SecureRandom.hex(3)}" }

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

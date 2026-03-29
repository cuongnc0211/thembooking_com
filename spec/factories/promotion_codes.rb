FactoryBot.define do
  factory :promotion_code do
    code { Faker::Alphanumeric.unique.alphanumeric(number: 8).upcase }
    discount_type { :percentage }
    discount_value { 10 }
    usage_limit { nil }
    used_count { 0 }
    valid_from { nil }
    valid_until { nil }
    active { true }
    description { nil }

    trait :percentage do
      discount_type { :percentage }
      discount_value { 10 }
    end

    trait :fixed_amount do
      discount_type { :fixed_amount }
      discount_value { 5.00 }
    end

    trait :inactive do
      active { false }
    end

    trait :expired do
      valid_until { 1.day.ago }
    end

    trait :with_limit do
      usage_limit { 10 }
    end

    trait :exhausted do
      usage_limit { 5 }
      used_count { 5 }
    end
  end
end

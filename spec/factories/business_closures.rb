FactoryBot.define do
  factory :business_closure do
    association :business
    date { Date.tomorrow }
    reason { nil }
  end
end

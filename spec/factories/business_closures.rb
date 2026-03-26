FactoryBot.define do
  factory :business_closure do
    association :branch
    date { Date.tomorrow }
    reason { nil }
  end
end

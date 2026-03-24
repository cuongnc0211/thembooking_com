FactoryBot.define do
  factory :service_category do
    association :branch
    sequence(:name) { |n| "Category #{n}" }
    position { 0 }
  end
end

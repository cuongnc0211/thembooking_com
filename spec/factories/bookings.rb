FactoryBot.define do
  factory :booking do
    business { nil }
    service { nil }
    customer_name { "MyString" }
    customer_email { "MyString" }
    customer_phone { "MyString" }
    scheduled_at { "2025-11-26 14:38:13" }
    status { 1 }
    source { 1 }
    notes { "MyText" }
    started_at { "2025-11-26 14:38:13" }
    completed_at { "2025-11-26 14:38:13" }
  end
end

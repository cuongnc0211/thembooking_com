FactoryBot.define do
  factory :admin_session do
    staff
    ip_address { Faker::Internet.ip_v4_address }
    user_agent { Faker::Internet.user_agent }
  end
end

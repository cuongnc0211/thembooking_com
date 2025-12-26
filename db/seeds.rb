# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

puts "======creating user======="
user = User.find_or_create_by!(email_address: 'user_1@example.com') do |u|
  u.password = '123123123'
  u.email_confirmed_at = Time.zone.now
end
puts "found/created user: #{user.email_address}"
user.reload

puts "======creating business======"
business = Business.build(
  user: user,
  name: "Cuong Barber",
  address: '79 - Cau Giay - Ha Noi',
  business_type: 'barber',
  slug: 'cuong-barber',
  capacity: 3,
  phone: '+84355619678'
)
business.save
puts "found/created business: #{business.name} (#{business.business_type})"
logo_path = Rails.root.join('public', 'development', 'logo.png')

business.reload
if File.exist?(logo_path)
  File.open(logo_path) do |file|
    business.logo.attach(io: file, filename: 'logo.png', content_type: 'image/png')
  end
end

puts "======creating services======"
SERVICES = [
  'Cắt tóc',
  'Nhuộm tóc',
  'Gội đầu',
  'Uốn tóc'
]

Money.default_formatting_rules
business.reload
SERVICES.each_with_index do |name, index|
  service = Service.build(
    business: business,
    name: name,
    duration_minutes: [30, 45, 60].sample,
    description: "Dịch vụ #{name}",
    position: index + 1,
    price: Money.from_cents((5..10).to_a.sample * 10_000, :VND)
  )
  service.save
  puts "found/created service: #{service.name}"
end

puts "======creating time slots======"
Slots::GenerateForBusiness.new(business: business).call
puts "generated time slot"

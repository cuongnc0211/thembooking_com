namespace :slots do
  desc "Generate initial slots for all businesses (7 days ahead)"
  task generate_initial: :environment do
    puts "Generating initial slots for all businesses..."

    total_businesses = Business.count
    total_slots_created = 0

    Business.find_each.with_index do |business, index|
      puts "\n[#{index + 1}/#{total_businesses}] Processing: #{business.name} (ID: #{business.id})"

      business_slots_created = 0

      7.times do |day_offset|
        date = Date.current + day_offset.days
        result = Slots::GenerateForBusiness.new(business: business, date: date).call

        business_slots_created += result[:slots_created]
        puts "  #{date.strftime('%a %Y-%m-%d')}: #{result[:slots_created]} slots"
      end

      total_slots_created += business_slots_created
      puts "  Total for #{business.name}: #{business_slots_created} slots"
    end

    puts "\n" + "=" * 60
    puts "✅ Done!"
    puts "Total businesses processed: #{total_businesses}"
    puts "Total slots created: #{total_slots_created}"
    puts "=" * 60
  end

  desc "Generate slots for a specific business and date"
  task :generate, [ :business_id, :date ] => :environment do |_t, args|
    unless args[:business_id]
      puts "❌ Error: business_id is required"
      puts "Usage: rails slots:generate[BUSINESS_ID,DATE]"
      puts "Example: rails slots:generate[1,2025-12-30]"
      exit 1
    end

    business = Business.find_by(id: args[:business_id])
    unless business
      puts "❌ Error: Business with ID #{args[:business_id]} not found"
      exit 1
    end

    date = args[:date] ? Date.parse(args[:date]) : Date.tomorrow
    puts "Generating slots for #{business.name} on #{date}..."

    result = Slots::GenerateForBusiness.new(business: business, date: date).call

    if result[:success]
      puts "✅ #{result[:message]}"
    else
      puts "❌ Failed: #{result[:message]}"
    end
  end

  desc "Clear all slots for testing (DANGEROUS - use only in development)"
  task clear_all: :environment do
    unless Rails.env.development? || Rails.env.test?
      puts "❌ This task can only be run in development or test environment"
      exit 1
    end

    puts "⚠️  WARNING: This will delete ALL slots from the database"
    print "Are you sure? (yes/no): "
    confirmation = STDIN.gets.chomp

    if confirmation.downcase == "yes"
      count = Slot.count
      Slot.delete_all
      puts "✅ Deleted #{count} slots"
    else
      puts "Cancelled"
    end
  end

  desc "Show slot statistics"
  task stats: :environment do
    total_slots = Slot.count
    total_businesses = Business.count
    businesses_with_slots = Business.joins(:slots).distinct.count

    puts "=" * 60
    puts "SLOT STATISTICS"
    puts "=" * 60
    puts "Total businesses: #{total_businesses}"
    puts "Businesses with slots: #{businesses_with_slots}"
    puts "Total slots: #{total_slots}"
    puts "Average slots per business: #{businesses_with_slots > 0 ? (total_slots.to_f / businesses_with_slots).round(2) : 0}"
    puts ""
    puts "Slots by date:"
    Slot.group(:date).order(:date).count.each do |date, count|
      puts "  #{date.strftime('%a %Y-%m-%d')}: #{count} slots"
    end
    puts "=" * 60
  end
end

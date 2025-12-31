require "rails_helper"

RSpec.describe GenerateDailySlotsJob, type: :job do
  describe "#perform" do
    let!(:business1) { create(:business, name: "Business 1", capacity: 3) }
    let!(:business2) { create(:business, name: "Business 2", capacity: 2) }
    let!(:business3) { create(:business, name: "Business 3", capacity: 4) }

    before do
      # Set up operating hours for businesses
      [ business1, business2, business3 ].each do |business|
        business.update!(
          operating_hours: {
            "monday" => { "open" => "09:00", "close" => "12:00", "closed" => false, "breaks" => [] },
            "tuesday" => { "open" => "09:00", "close" => "12:00", "closed" => false, "breaks" => [] },
            "wednesday" => { "open" => "09:00", "close" => "12:00", "closed" => false, "breaks" => [] },
            "thursday" => { "open" => "09:00", "close" => "12:00", "closed" => false, "breaks" => [] },
            "friday" => { "open" => "09:00", "close" => "12:00", "closed" => false, "breaks" => [] },
            "saturday" => { "closed" => true },
            "sunday" => { "closed" => true }
          }
        )
      end
    end

    it "generates slots for tomorrow for all businesses" do
      job = described_class.new
      job.perform

      # Check that slots were created for all businesses
      # Tomorrow's date
      tomorrow = Date.tomorrow

      expect(business1.slots.for_date(tomorrow).count).to be > 0
      expect(business2.slots.for_date(tomorrow).count).to be > 0
      expect(business3.slots.for_date(tomorrow).count).to be > 0
    end

    it "calls Slots::GenerateForBusiness with correct date for each business" do
      # Mock the service to verify it's called with correct params
      allow(Slots::GenerateForBusiness).to receive(:new).and_call_original

      job = described_class.new
      job.perform

      expect(Slots::GenerateForBusiness).to have_received(:new).with(
        business: business1,
        date: Date.tomorrow
      )
      expect(Slots::GenerateForBusiness).to have_received(:new).with(
        business: business2,
        date: Date.tomorrow
      )
      expect(Slots::GenerateForBusiness).to have_received(:new).with(
        business: business3,
        date: Date.tomorrow
      )
    end

    it "logs results for each business" do
      allow(Rails.logger).to receive(:info)

      job = described_class.new
      job.perform

      expect(Rails.logger).to have_received(:info).at_least(3).times
    end

    context "when a business is closed tomorrow" do
      let!(:business_closed) do
        business = create(:business, name: "Closed Business")
        business.update!(
          operating_hours: {
            "monday" => { "closed" => true },
            "tuesday" => { "closed" => true },
            "wednesday" => { "closed" => true },
            "thursday" => { "closed" => true },
            "friday" => { "closed" => true },
            "saturday" => { "closed" => true },
            "sunday" => { "closed" => true }
          }
        )
        business
      end

      it "continues processing other businesses and creates 0 slots for closed business" do
        job = described_class.new
        job.perform

        # Should still create slots for businesses with operating hours
        tomorrow = Date.tomorrow
        expect(business1.slots.for_date(tomorrow).count).to be > 0
        expect(business2.slots.for_date(tomorrow).count).to be > 0
        expect(business3.slots.for_date(tomorrow).count).to be > 0

        # Business that is closed should have 0 slots
        expect(business_closed.slots.for_date(tomorrow).count).to eq(0)
      end
    end

    context "when job is run on different days" do
      it "generates slots for the next day (rolling window)" do
        # Simulate running the job today
        travel_to Time.zone.parse("2025-12-29 02:00") do # Monday 2am
          job = described_class.new
          job.perform

          # Should create slots for Tuesday (tomorrow)
          tuesday = Date.new(2025, 12, 30)
          expect(business1.slots.for_date(tuesday).count).to be > 0
        end
      end

      it "does not create duplicate slots if run multiple times" do
        job = described_class.new

        # Run first time
        job.perform
        first_count = business1.slots.for_date(Date.tomorrow).count

        # Run second time
        job.perform
        second_count = business1.slots.for_date(Date.tomorrow).count

        # Count should be the same (no duplicates)
        expect(second_count).to eq(first_count)
      end
    end

    context "when tomorrow is a closed day" do
      it "creates 0 slots for that business" do
        travel_to Time.zone.parse("2025-12-27 02:00") do # Saturday 2am
          job = described_class.new
          job.perform

          # Sunday is closed for all businesses
          sunday = Date.new(2025, 12, 28)
          expect(business1.slots.for_date(sunday).count).to eq(0)
          expect(business2.slots.for_date(sunday).count).to eq(0)
          expect(business3.slots.for_date(sunday).count).to eq(0)
        end
      end
    end
  end
end

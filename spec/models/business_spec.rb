require "rails_helper"

RSpec.describe Business, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    subject { build(:business) }

    describe "name" do
      it { is_expected.to validate_presence_of(:name) }
      it { is_expected.to validate_length_of(:name).is_at_most(100) }
    end

    describe "slug" do
      it { is_expected.to validate_presence_of(:slug) }
      it { is_expected.to validate_uniqueness_of(:slug).case_insensitive }
      it { is_expected.to validate_length_of(:slug).is_at_least(3).is_at_most(50) }

      it "only allows lowercase letters, numbers, and hyphens" do
        business = build(:business, slug: "valid-slug-123")
        expect(business).to be_valid

        business.slug = "Invalid Slug!"
        expect(business).not_to be_valid
        expect(business.errors[:slug]).to include("can only contain lowercase letters, numbers, and hyphens")
      end

      it "normalizes slug to lowercase and strips whitespace" do
        business = build(:business, slug: "  MY-SHOP  ")
        expect(business.slug).to eq("my-shop")
      end
    end

    describe "business_type" do
      it { is_expected.to validate_presence_of(:business_type) }

      it "defines correct enum values" do
        expect(Business.business_types.keys).to contain_exactly("barber", "salon", "spa", "nail", "other")
      end
    end

    describe "capacity" do
      it { is_expected.to validate_presence_of(:capacity) }
      it { is_expected.to validate_numericality_of(:capacity).only_integer.is_greater_than(0).is_less_than_or_equal_to(50) }
    end

    describe "phone" do
      it "allows valid phone formats" do
        business = build(:business, phone: "+84 123 456 789")
        expect(business).to be_valid

        business.phone = "0123-456-789"
        expect(business).to be_valid
      end

      it "rejects invalid phone formats" do
        business = build(:business, phone: "abc123")
        expect(business).not_to be_valid
      end

      it "allows blank phone" do
        business = build(:business, phone: "")
        expect(business).to be_valid
      end
    end
  end

  describe "#booking_url" do
    it "returns the public booking URL" do
      business = build(:business, slug: "johns-barbershop")
      expect(business.booking_url).to eq("johns-barbershop.thembooking.com")
    end
  end

  describe "user association" do
    it "enforces one business per user" do
      user = create(:user)
      create(:business, user: user, slug: "first-shop")

      second_business = build(:business, user: user, slug: "second-shop")
      expect(second_business).not_to be_valid
    end
  end

  describe "operating hours" do
    describe "default values" do
      it "initializes with default operating hours for new records" do
        business = Business.new(name: "Test", user: build(:user))

        expect(business.operating_hours).to be_present
        expect(business.operating_hours.keys).to contain_exactly(
          "monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"
        )

        # Check structure of a weekday
        monday = business.operating_hours["monday"]
        expect(monday).to include("open", "close", "closed", "breaks")
        expect(monday["open"]).to eq("09:00")
        expect(monday["close"]).to eq("17:00")
        expect(monday["closed"]).to be false
        expect(monday["breaks"]).to be_an(Array) # Don't hardcode default breaks - they may change

        # Check Sunday is closed by default
        sunday = business.operating_hours["sunday"]
        expect(sunday["closed"]).to be true
        expect(sunday["open"]).to be_nil
        expect(sunday["close"]).to be_nil
        expect(sunday["breaks"]).to be_an(Array)
      end

      it "does not override existing operating hours" do
        business = build(:business, operating_hours: { "monday" => { "open" => "10:00", "close" => "18:00", "closed" => false, "breaks" => [] } })
        expect(business.operating_hours["monday"]["open"]).to eq("10:00")
      end
    end

    describe "validations" do
      describe "operating hours format" do
        it "is valid with correct structure" do
          business = build(:business, operating_hours: {
            "monday" => { "open" => "09:00", "close" => "17:00", "closed" => false, "breaks" => [] }
          })
          expect(business).to be_valid
        end

        it "is invalid when open time is missing for open days" do
          business = build(:business, operating_hours: {
            "monday" => { "open" => nil, "close" => "17:00", "closed" => false, "breaks" => [] }
          })
          expect(business).not_to be_valid
          expect(business.errors[:operating_hours]).to include("Monday must have an opening time")
        end

        it "is invalid when close time is missing for open days" do
          business = build(:business, operating_hours: {
            "monday" => { "open" => "09:00", "close" => nil, "closed" => false, "breaks" => [] }
          })
          expect(business).not_to be_valid
          expect(business.errors[:operating_hours]).to include("Monday must have a closing time")
        end

        it "allows nil times for closed days" do
          business = build(:business, operating_hours: {
            "sunday" => { "open" => nil, "close" => nil, "closed" => true, "breaks" => [] }
          })
          expect(business).to be_valid
        end
      end

      describe "operating hours logic" do
        it "is invalid when close time is before open time" do
          business = build(:business, operating_hours: {
            "monday" => { "open" => "17:00", "close" => "09:00", "closed" => false, "breaks" => [] }
          })
          expect(business).not_to be_valid
          expect(business.errors[:operating_hours]).to include("Monday closing time must be after opening time")
        end

        it "is invalid when open and close times are the same" do
          business = build(:business, operating_hours: {
            "monday" => { "open" => "09:00", "close" => "09:00", "closed" => false, "breaks" => [] }
          })
          expect(business).not_to be_valid
          expect(business.errors[:operating_hours]).to include("Monday closing time must be after opening time")
        end

        it "skips time logic validation for closed days" do
          business = build(:business, operating_hours: {
            "sunday" => { "open" => "17:00", "close" => "09:00", "closed" => true, "breaks" => [] }
          })
          expect(business).to be_valid
        end
      end

      describe "break times" do
        it "is valid with break times within operating hours" do
          business = build(:business, operating_hours: {
            "monday" => {
              "open" => "09:00",
              "close" => "17:00",
              "closed" => false,
              "breaks" => [
                { "start" => "12:00", "end" => "13:00" }
              ]
            }
          })
          expect(business).to be_valid
        end

        it "is invalid when break start is before opening time" do
          business = build(:business, operating_hours: {
            "monday" => {
              "open" => "09:00",
              "close" => "17:00",
              "closed" => false,
              "breaks" => [
                { "start" => "08:00", "end" => "09:00" }
              ]
            }
          })
          expect(business).not_to be_valid
          expect(business.errors[:operating_hours]).to include("Monday break must be within operating hours (09:00 - 17:00)")
        end

        it "is invalid when break end is after closing time" do
          business = build(:business, operating_hours: {
            "monday" => {
              "open" => "09:00",
              "close" => "17:00",
              "closed" => false,
              "breaks" => [
                { "start" => "16:00", "end" => "18:00" }
              ]
            }
          })
          expect(business).not_to be_valid
          expect(business.errors[:operating_hours]).to include("Monday break must be within operating hours (09:00 - 17:00)")
        end

        it "is invalid when break end is before break start" do
          business = build(:business, operating_hours: {
            "monday" => {
              "open" => "09:00",
              "close" => "17:00",
              "closed" => false,
              "breaks" => [
                { "start" => "13:00", "end" => "12:00" }
              ]
            }
          })
          expect(business).not_to be_valid
          expect(business.errors[:operating_hours]).to include("Monday break end time must be after start time")
        end

        it "is invalid when breaks overlap" do
          business = build(:business, operating_hours: {
            "monday" => {
              "open" => "09:00",
              "close" => "17:00",
              "closed" => false,
              "breaks" => [
                { "start" => "12:00", "end" => "13:30" },
                { "start" => "13:00", "end" => "14:00" }
              ]
            }
          })
          expect(business).not_to be_valid
          expect(business.errors[:operating_hours]).to include("Monday has overlapping break times")
        end

        it "allows multiple non-overlapping breaks" do
          business = build(:business, operating_hours: {
            "monday" => {
              "open" => "09:00",
              "close" => "19:00",
              "closed" => false,
              "breaks" => [
                { "start" => "12:00", "end" => "13:00" },
                { "start" => "17:00", "end" => "17:30" }
              ]
            }
          })
          expect(business).to be_valid
        end
      end
    end

    describe "helper methods" do
      let(:business) do
        build(:business, operating_hours: {
          "monday" => {
            "open" => "09:00",
            "close" => "17:00",
            "closed" => false,
            "breaks" => [
              { "start" => "12:00", "end" => "13:00" }
            ]
          },
          "sunday" => {
            "open" => nil,
            "close" => nil,
            "closed" => true,
            "breaks" => []
          }
        })
      end

      describe "#open_on?" do
        it "returns true for open days" do
          expect(business.open_on?("monday")).to be true
        end

        it "returns false for closed days" do
          expect(business.open_on?("sunday")).to be false
        end
      end

      describe "#hours_for" do
        it "returns hash with open/close/breaks for a given day" do
          hours = business.hours_for("monday")

          expect(hours).to be_a(Hash)
          expect(hours["open"]).to eq("09:00")
          expect(hours["close"]).to eq("17:00")
          expect(hours["closed"]).to be false
          expect(hours["breaks"]).to eq([{ "start" => "12:00", "end" => "13:00" }])
        end

        it "returns nil for invalid day" do
          expect(business.hours_for("invalid_day")).to be_nil
        end
      end

      describe "#operating_on?" do
        let(:business_datetime) { Time.zone.parse("2025-01-06 10:00") } # Monday

        it "returns true when datetime is within operating hours and not on break" do
          expect(business.operating_on?(business_datetime)).to be true
        end

        it "returns false when datetime is during a break" do
          break_time = Time.zone.parse("2025-01-06 12:30") # Monday lunch break
          expect(business.operating_on?(break_time)).to be false
        end

        it "returns false when datetime is before opening time" do
          before_open = Time.zone.parse("2025-01-06 08:00") # Monday before 9am
          expect(business.operating_on?(before_open)).to be false
        end

        it "returns false when datetime is after closing time" do
          after_close = Time.zone.parse("2025-01-06 18:00") # Monday after 5pm
          expect(business.operating_on?(after_close)).to be false
        end

        it "returns false on closed days" do
          sunday = Time.zone.parse("2025-01-05 10:00") # Sunday
          expect(business.operating_on?(sunday)).to be false
        end
      end

      describe "#on_break?" do
        it "returns true when datetime falls within a break period" do
          break_time = Time.zone.parse("2025-01-06 12:30") # Monday 12:30pm
          expect(business.on_break?(break_time)).to be true
        end

        it "returns false when datetime is not during a break" do
          working_time = Time.zone.parse("2025-01-06 10:00") # Monday 10am
          expect(business.on_break?(working_time)).to be false
        end

        it "returns false on days with no breaks" do
          sunday = Time.zone.parse("2025-01-05 10:00") # Sunday
          expect(business.on_break?(sunday)).to be false
        end
      end
    end
  end
end

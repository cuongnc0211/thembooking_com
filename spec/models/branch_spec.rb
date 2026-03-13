require "rails_helper"

RSpec.describe Branch, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:business) }
    it { is_expected.to have_many(:services).dependent(:destroy) }
    it { is_expected.to have_many(:bookings).dependent(:destroy) }
    it { is_expected.to have_many(:business_closures).dependent(:destroy) }
  end

  describe "validations" do
    subject { build(:branch) }

    describe "name" do
      it { is_expected.to validate_presence_of(:name) }
    end

    describe "slug" do
      it { is_expected.to validate_presence_of(:slug) }
      it { is_expected.to validate_uniqueness_of(:slug).case_insensitive }
      it { is_expected.to validate_length_of(:slug).is_at_least(3).is_at_most(50) }

      it "only allows lowercase letters, numbers, and hyphens" do
        branch = build(:branch, slug: "valid-slug-123")
        expect(branch).to be_valid

        branch.slug = "Invalid Slug!"
        expect(branch).not_to be_valid
        expect(branch.errors[:slug]).to be_present
      end

      it "normalizes slug to lowercase and strips whitespace" do
        branch = build(:branch, slug: "  MY-SHOP  ")
        expect(branch.slug).to eq("my-shop")
      end
    end

    describe "capacity" do
      it { is_expected.to validate_presence_of(:capacity) }
      it { is_expected.to validate_numericality_of(:capacity).only_integer.is_greater_than(0).is_less_than_or_equal_to(50) }
    end

    describe "phone" do
      it "allows valid phone formats" do
        branch = build(:branch, phone: "+84 123 456 789")
        expect(branch).to be_valid

        branch.phone = "0123-456-789"
        expect(branch).to be_valid
      end

      it "rejects invalid phone formats" do
        branch = build(:branch, phone: "abc123")
        expect(branch).not_to be_valid
      end

      it "allows blank phone" do
        branch = build(:branch, phone: "")
        expect(branch).to be_valid
      end
    end
  end

  describe "#booking_url" do
    it "returns the public booking URL" do
      branch = build(:branch, slug: "johns-barbershop")
      expect(branch.booking_url).to eq("thembooking.com/johns-barbershop")
    end
  end

  describe "operating hours" do
    describe "default values" do
      it "initializes with default operating hours for new records" do
        branch = Branch.new(name: "Test", business: build(:business))

        expect(branch.operating_hours).to be_present
        expect(branch.operating_hours.keys).to contain_exactly(
          "monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"
        )

        monday = branch.operating_hours["monday"]
        expect(monday).to include("open", "close", "closed", "breaks")
        expect(monday["open"]).to eq("09:00")
        expect(monday["close"]).to eq("17:00")
        expect(monday["closed"]).to be false
        expect(monday["breaks"]).to be_an(Array)

        sunday = branch.operating_hours["sunday"]
        expect(sunday["closed"]).to be true
        expect(sunday["open"]).to be_nil
        expect(sunday["close"]).to be_nil
        expect(sunday["breaks"]).to be_an(Array)
      end

      it "does not override existing operating hours" do
        branch = build(:branch, operating_hours: { "monday" => { "open" => "10:00", "close" => "18:00", "closed" => false, "breaks" => [] } })
        expect(branch.operating_hours["monday"]["open"]).to eq("10:00")
      end
    end

    describe "validations" do
      describe "operating hours format" do
        it "is valid with correct structure" do
          branch = build(:branch, operating_hours: {
            "monday" => { "open" => "09:00", "close" => "17:00", "closed" => false, "breaks" => [] }
          })
          expect(branch).to be_valid
        end

        it "is invalid when open time is missing for open days" do
          branch = build(:branch, operating_hours: {
            "monday" => { "open" => nil, "close" => "17:00", "closed" => false, "breaks" => [] }
          })
          expect(branch).not_to be_valid
          expect(branch.errors[:operating_hours]).to include("Monday must have an opening time")
        end

        it "is invalid when close time is missing for open days" do
          branch = build(:branch, operating_hours: {
            "monday" => { "open" => "09:00", "close" => nil, "closed" => false, "breaks" => [] }
          })
          expect(branch).not_to be_valid
          expect(branch.errors[:operating_hours]).to include("Monday must have a closing time")
        end

        it "allows nil times for closed days" do
          branch = build(:branch, operating_hours: {
            "sunday" => { "open" => nil, "close" => nil, "closed" => true, "breaks" => [] }
          })
          expect(branch).to be_valid
        end
      end

      describe "operating hours logic" do
        it "is invalid when close time is before open time" do
          branch = build(:branch, operating_hours: {
            "monday" => { "open" => "17:00", "close" => "09:00", "closed" => false, "breaks" => [] }
          })
          expect(branch).not_to be_valid
          expect(branch.errors[:operating_hours]).to include("Monday closing time must be after opening time")
        end

        it "is invalid when open and close times are the same" do
          branch = build(:branch, operating_hours: {
            "monday" => { "open" => "09:00", "close" => "09:00", "closed" => false, "breaks" => [] }
          })
          expect(branch).not_to be_valid
          expect(branch.errors[:operating_hours]).to include("Monday closing time must be after opening time")
        end

        it "skips time logic validation for closed days" do
          branch = build(:branch, operating_hours: {
            "sunday" => { "open" => "17:00", "close" => "09:00", "closed" => true, "breaks" => [] }
          })
          expect(branch).to be_valid
        end
      end

      describe "break times" do
        it "is valid with break times within operating hours" do
          branch = build(:branch, operating_hours: {
            "monday" => {
              "open" => "09:00", "close" => "17:00", "closed" => false,
              "breaks" => [ { "start" => "12:00", "end" => "13:00" } ]
            }
          })
          expect(branch).to be_valid
        end

        it "is invalid when break start is before opening time" do
          branch = build(:branch, operating_hours: {
            "monday" => {
              "open" => "09:00", "close" => "17:00", "closed" => false,
              "breaks" => [ { "start" => "08:00", "end" => "09:00" } ]
            }
          })
          expect(branch).not_to be_valid
          expect(branch.errors[:operating_hours]).to include("Monday break must be within operating hours (09:00 - 17:00)")
        end

        it "is invalid when break end is after closing time" do
          branch = build(:branch, operating_hours: {
            "monday" => {
              "open" => "09:00", "close" => "17:00", "closed" => false,
              "breaks" => [ { "start" => "16:00", "end" => "18:00" } ]
            }
          })
          expect(branch).not_to be_valid
          expect(branch.errors[:operating_hours]).to include("Monday break must be within operating hours (09:00 - 17:00)")
        end

        it "is invalid when break end is before break start" do
          branch = build(:branch, operating_hours: {
            "monday" => {
              "open" => "09:00", "close" => "17:00", "closed" => false,
              "breaks" => [ { "start" => "13:00", "end" => "12:00" } ]
            }
          })
          expect(branch).not_to be_valid
          expect(branch.errors[:operating_hours]).to include("Monday break end time must be after start time")
        end

        it "is invalid when breaks overlap" do
          branch = build(:branch, operating_hours: {
            "monday" => {
              "open" => "09:00", "close" => "17:00", "closed" => false,
              "breaks" => [
                { "start" => "12:00", "end" => "13:30" },
                { "start" => "13:00", "end" => "14:00" }
              ]
            }
          })
          expect(branch).not_to be_valid
          expect(branch.errors[:operating_hours]).to include("Monday has overlapping break times")
        end

        it "allows multiple non-overlapping breaks" do
          branch = build(:branch, operating_hours: {
            "monday" => {
              "open" => "09:00", "close" => "19:00", "closed" => false,
              "breaks" => [
                { "start" => "12:00", "end" => "13:00" },
                { "start" => "17:00", "end" => "17:30" }
              ]
            }
          })
          expect(branch).to be_valid
        end
      end
    end

    describe "helper methods" do
      let(:branch) do
        build(:branch, operating_hours: {
          "monday" => {
            "open" => "09:00", "close" => "17:00", "closed" => false,
            "breaks" => [ { "start" => "12:00", "end" => "13:00" } ]
          },
          "sunday" => { "open" => nil, "close" => nil, "closed" => true, "breaks" => [] }
        })
      end

      describe "#open_on?" do
        it "returns true for open days" do
          expect(branch.open_on?("monday")).to be true
        end

        it "returns false for closed days" do
          expect(branch.open_on?("sunday")).to be false
        end
      end

      describe "#hours_for" do
        it "returns hash with open/close/breaks for a given day" do
          hours = branch.hours_for("monday")
          expect(hours).to be_a(Hash)
          expect(hours["open"]).to eq("09:00")
          expect(hours["close"]).to eq("17:00")
          expect(hours["closed"]).to be false
          expect(hours["breaks"]).to eq([ { "start" => "12:00", "end" => "13:00" } ])
        end

        it "returns nil for invalid day" do
          expect(branch.hours_for("invalid_day")).to be_nil
        end
      end

      describe "#operating_on?" do
        let(:datetime) { Time.zone.parse("2025-01-06 10:00") } # Monday

        it "returns true when datetime is within operating hours and not on break" do
          expect(branch.operating_on?(datetime)).to be true
        end

        it "returns false when datetime is during a break" do
          expect(branch.operating_on?(Time.zone.parse("2025-01-06 12:30"))).to be false
        end

        it "returns false when datetime is before opening time" do
          expect(branch.operating_on?(Time.zone.parse("2025-01-06 08:00"))).to be false
        end

        it "returns false when datetime is after closing time" do
          expect(branch.operating_on?(Time.zone.parse("2025-01-06 18:00"))).to be false
        end

        it "returns false on closed days" do
          expect(branch.operating_on?(Time.zone.parse("2025-01-05 10:00"))).to be false
        end
      end

      describe "#on_break?" do
        it "returns true when datetime falls within a break period" do
          expect(branch.on_break?(Time.zone.parse("2025-01-06 12:30"))).to be true
        end

        it "returns false when datetime is not during a break" do
          expect(branch.on_break?(Time.zone.parse("2025-01-06 10:00"))).to be false
        end

        it "returns false on days with no breaks" do
          expect(branch.on_break?(Time.zone.parse("2025-01-05 10:00"))).to be false
        end
      end
    end
  end
end

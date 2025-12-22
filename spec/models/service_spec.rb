require "rails_helper"

RSpec.describe Service, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:business) }
  end

  describe "validations" do
    subject { build(:service) }

    describe "name" do
      it { is_expected.to validate_presence_of(:name) }
      it { is_expected.to validate_length_of(:name).is_at_most(100) }

      it "validates uniqueness scoped to business" do
        service = create(:service, name: "Haircut")
        duplicate = build(:service, name: "Haircut", business: service.business)
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:name]).to include("is already taken for this business")
      end

      it "allows same name in different businesses" do
        service1 = create(:service, name: "Haircut")
        service2 = build(:service, name: "Haircut", business: create(:business, user: create(:user), slug: "another-shop"))
        expect(service2).to be_valid
      end
    end

    describe "duration_minutes" do
      it { is_expected.to validate_presence_of(:duration_minutes) }
      it { is_expected.to validate_inclusion_of(:duration_minutes).in_array([ 15, 30, 45, 60, 90, 120 ]) }

      it "rejects invalid durations" do
        service = build(:service, duration_minutes: 25)
        expect(service).not_to be_valid
        expect(service.errors[:duration_minutes]).to include("is not a valid duration")
      end
    end

    describe "price" do
      it "validates presence of price_cents" do
        service = build(:service, price_cents: nil)
        expect(service).not_to be_valid
      end

      it "validates price is greater than 0" do
        service = build(:service, price_cents: 0)
        expect(service).not_to be_valid
        expect(service.errors[:price_cents]).to include("must be greater than 0")
      end

      it "accepts valid prices" do
        service = build(:service, price_cents: 8000000) # 80,000 VND
        expect(service).to be_valid
      end
    end

    describe "currency" do
      it "defaults to VND" do
        service = Service.new
        expect(service.currency).to eq("VND")
      end
    end

    describe "active" do
      it "defaults to true" do
        service = Service.new
        expect(service.active).to be true
      end
    end

    describe "position" do
      it "defaults to 0" do
        service = Service.new
        expect(service.position).to eq(0)
      end
    end
  end

  describe "monetize integration" do
    it "returns Money object for price" do
      service = build(:service, price_cents: 8000000, currency: "VND")
      expect(service.price).to be_a(Money)
      expect(service.price.cents).to eq(8000000)
      expect(service.price.currency.iso_code).to eq("VND")
    end

    it "allows setting price with Money object" do
      service = build(:service)
      service.price = Money.new(5000000, "VND")
      expect(service.price_cents).to eq(5000000)
    end

    it "allows setting price with numeric value" do
      service = build(:service)
      service.price = 50000 # Set price_cents directly to 50000
      expect(service.price_cents).to eq(50000)
      expect(service.price.format).to eq("50,000 ₫") # Formats as VND with symbol after amount
    end
  end

  describe "scopes and ordering" do
    let(:business) { create(:business) }

    it "can be ordered by position" do
      service1 = create(:service, business: business, position: 2)
      service2 = create(:service, business: business, position: 1, name: "Second Service")
      service3 = create(:service, business: business, position: 3, name: "Third Service")

      ordered_services = business.services.order(:position)
      expect(ordered_services).to eq([ service2, service1, service3 ])
    end

    it "can filter active services" do
      active_service = create(:service, business: business, active: true)
      inactive_service = create(:service, business: business, active: false, name: "Inactive Service")

      active_services = business.services.where(active: true)
      expect(active_services).to include(active_service)
      expect(active_services).not_to include(inactive_service)
    end
  end

  describe ".duration_options_for_select" do
    it "returns array of [label, value] pairs for select options" do
      options = Service.duration_options_for_select
      expect(options).to be_an(Array)
      expect(options).to include(["15 min", 15])
      expect(options).to include(["30 min", 30])
      expect(options).to include(["45 min", 45])
      expect(options).to include(["1 hour", 60])
      expect(options).to include(["1.5 hours", 90])
      expect(options).to include(["2 hours", 120])
    end

    it "returns options in correct order" do
      options = Service.duration_options_for_select
      expect(options.first).to eq(["15 min", 15])
      expect(options.last).to eq(["2 hours", 120])
    end
  end

  describe "DURATION_OPTIONS constant" do
    it "defines all valid duration values" do
      expect(Service::DURATION_OPTIONS).to be_frozen
      expect(Service::DURATION_OPTIONS.map { |o| o[:value] }).to eq([15, 30, 45, 60, 90, 120])
    end

    it "includes labels for each duration" do
      labels = Service::DURATION_OPTIONS.map { |o| o[:label] }
      expect(labels).to include("15 min", "30 min", "45 min", "1 hour", "1.5 hours", "2 hours")
    end
  end
end

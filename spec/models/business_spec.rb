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
        expect(business.errors[:slug]).to include("only allows lowercase letters, numbers, and hyphens")
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
end

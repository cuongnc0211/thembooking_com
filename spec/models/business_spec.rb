require "rails_helper"

RSpec.describe Business, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:branches).dependent(:destroy) }
    it { is_expected.to have_many(:services).through(:branches) }
    it { is_expected.to have_many(:bookings).through(:branches) }
  end

  describe "validations" do
    subject { build(:business) }

    describe "name" do
      it { is_expected.to validate_presence_of(:name) }
      it { is_expected.to validate_length_of(:name).is_at_most(100) }
    end

    describe "business_type" do
      it { is_expected.to validate_presence_of(:business_type) }

      it "defines correct enum values" do
        expect(Business.business_types.keys).to contain_exactly("barber", "salon", "spa", "nail", "other")
      end
    end
  end

  describe "user association" do
    it "enforces one business per user" do
      user = create(:user)
      create(:business, user: user)

      second_business = build(:business, user: user)
      expect(second_business).not_to be_valid
    end
  end
end

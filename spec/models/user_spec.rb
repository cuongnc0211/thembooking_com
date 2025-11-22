require "rails_helper"

RSpec.describe User, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:sessions).dependent(:destroy) }
    it { is_expected.to have_one(:business).dependent(:destroy) }
  end

  describe "validations" do
    subject { build(:user) }

    it { is_expected.to validate_presence_of(:email_address) }
    it { is_expected.to validate_uniqueness_of(:email_address).case_insensitive }

    it "validates email format" do
      user = build(:user, email_address: "invalid-email")
      expect(user).not_to be_valid
    end

    it "validates password minimum length" do
      user = build(:user, password: "short")
      expect(user).not_to be_valid
    end
  end

  describe "email confirmation" do
    it "is not confirmed by default on create" do
      user = create(:user, :unconfirmed)
      expect(user.confirmed?).to be false
    end

    it "can be confirmed" do
      user = create(:user, :unconfirmed)
      user.confirm!
      expect(user.confirmed?).to be true
      expect(user.email_confirmation_token).to be_nil
    end
  end

  describe "normalizations" do
    it "normalizes email to lowercase" do
      user = build(:user, email_address: "  TEST@Example.COM  ")
      expect(user.email_address).to eq("test@example.com")
    end
  end
end

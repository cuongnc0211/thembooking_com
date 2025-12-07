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

  describe "onboarding" do
    describe "constants" do
      it "defines ONBOARDING_STEPS hash" do
        expect(User::ONBOARDING_STEPS).to eq({
          user_info: 1,
          business: 2,
          hours: 3,
          services: 4,
          completed: 5
        })
      end
    end

    describe "#onboarding_completed?" do
      it "returns true when onboarding_completed_at is present" do
        user = build(:user, onboarding_completed_at: Time.current)
        expect(user.onboarding_completed?).to be true
      end

      it "returns false when onboarding_completed_at is nil" do
        user = build(:user, onboarding_completed_at: nil)
        expect(user.onboarding_completed?).to be false
      end
    end

    describe "#current_onboarding_step_name" do
      it "returns :user_info for step 1" do
        user = build(:user, onboarding_step: 1)
        expect(user.current_onboarding_step_name).to eq(:user_info)
      end

      it "returns :services for step 4" do
        user = build(:user, onboarding_step: 4)
        expect(user.current_onboarding_step_name).to eq(:services)
      end
    end

    describe "#advance_onboarding!" do
      let(:user) { create(:user, onboarding_step: 1) }

      it "increments onboarding_step by 1" do
        expect { user.advance_onboarding! }.to change { user.onboarding_step }.from(1).to(2)
      end

      it "sets onboarding_completed_at when advancing to step 5" do
        user.update!(onboarding_step: 4)
        expect { user.advance_onboarding! }.to change { user.onboarding_completed_at }.from(nil)
      end

      it "does not advance beyond step 5" do
        user.update!(onboarding_step: 5)
        expect { user.advance_onboarding! }.not_to change { user.onboarding_step }
      end
    end

    describe "#can_access_step?" do
      let(:user) { build(:user, onboarding_step: 3) }

      it "returns true for current step" do
        expect(user.can_access_step?(3)).to be true
      end

      it "returns true for previous steps" do
        expect(user.can_access_step?(1)).to be true
        expect(user.can_access_step?(2)).to be true
      end

      it "returns false for future steps" do
        expect(user.can_access_step?(4)).to be false
      end
    end

    describe "#onboarding_step_complete?" do
      context "step 1 (user_info)" do
        it "returns true when name and phone present" do
          user = build(:user, name: "John", phone: "0901234567")
          expect(user.onboarding_step_complete?(1)).to be true
        end

        it "returns false when name blank" do
          user = build(:user, name: nil, phone: "0901234567")
          expect(user.onboarding_step_complete?(1)).to be false
        end
      end

      context "step 2 (business)" do
        it "returns true when user has business" do
          user = create(:user)
          create(:business, user: user)
          expect(user.onboarding_step_complete?(2)).to be true
        end

        it "returns false when no business" do
          user = create(:user)
          expect(user.onboarding_step_complete?(2)).to be false
        end
      end

      context "step 3 (hours)" do
        it "returns true when business has operating_hours" do
          user = create(:user)
          create(:business, user: user)
          expect(user.onboarding_step_complete?(3)).to be true
        end
      end

      context "step 4 (services)" do
        it "returns true when business has at least one service" do
          user = create(:user)
          business = create(:business, user: user)
          create(:service, business: business)
          expect(user.onboarding_step_complete?(4)).to be true
        end

        it "returns false when no services" do
          user = create(:user)
          create(:business, user: user)
          expect(user.onboarding_step_complete?(4)).to be false
        end
      end
    end
  end
end

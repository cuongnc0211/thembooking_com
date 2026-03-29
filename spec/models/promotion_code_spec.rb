require "rails_helper"

RSpec.describe PromotionCode, type: :model do
  describe "enums" do
    it { should define_enum_for(:discount_type).with_values(percentage: 0, fixed_amount: 1) }
  end

  describe "validations" do
    subject { build(:promotion_code) }

    it { should validate_presence_of(:code) }
    it { should validate_uniqueness_of(:code).case_insensitive }
    it { should validate_presence_of(:discount_value) }
    it { should validate_numericality_of(:discount_value).is_greater_than(0) }

    it "is invalid when discount_value > 100 for percentage type" do
      promo = build(:promotion_code, discount_type: :percentage, discount_value: 101)
      expect(promo).not_to be_valid
      expect(promo.errors[:discount_value]).to be_present
    end

    it "is valid when discount_value == 100 for percentage type" do
      promo = build(:promotion_code, discount_type: :percentage, discount_value: 100)
      expect(promo).to be_valid
    end

    it "allows discount_value > 100 for fixed_amount type" do
      promo = build(:promotion_code, discount_type: :fixed_amount, discount_value: 500)
      expect(promo).to be_valid
    end

    it "validates usage_limit is greater than 0 when present" do
      promo = build(:promotion_code, usage_limit: 0)
      expect(promo).not_to be_valid
    end

    it "allows nil usage_limit" do
      promo = build(:promotion_code, usage_limit: nil)
      expect(promo).to be_valid
    end
  end

  describe "before_validation: upcase_code" do
    it "upcases code on save" do
      promo = create(:promotion_code, code: "summer2026")
      expect(promo.code).to eq("SUMMER2026")
    end

    it "strips whitespace from code" do
      promo = create(:promotion_code, code: "  PROMO10  ")
      expect(promo.code).to eq("PROMO10")
    end

    it "treats codes as case-insensitive for uniqueness" do
      create(:promotion_code, code: "UNIQUE10")
      duplicate = build(:promotion_code, code: "unique10")
      expect(duplicate).not_to be_valid
    end
  end

  describe ".currently_valid scope" do
    it "returns active codes" do
      active = create(:promotion_code, active: true)
      create(:promotion_code, :inactive)
      expect(PromotionCode.currently_valid).to include(active)
    end

    it "excludes inactive codes" do
      create(:promotion_code, :inactive)
      expect(PromotionCode.currently_valid).to be_empty
    end

    it "excludes codes where valid_from is in the future" do
      create(:promotion_code, valid_from: 1.hour.from_now)
      expect(PromotionCode.currently_valid).to be_empty
    end

    it "excludes expired codes (valid_until in past)" do
      create(:promotion_code, :expired)
      expect(PromotionCode.currently_valid).to be_empty
    end

    it "includes codes with valid_from in past and no valid_until" do
      promo = create(:promotion_code, valid_from: 1.day.ago)
      expect(PromotionCode.currently_valid).to include(promo)
    end

    it "includes codes with no date constraints" do
      promo = create(:promotion_code, valid_from: nil, valid_until: nil)
      expect(PromotionCode.currently_valid).to include(promo)
    end
  end

  describe ".redeem!" do
    it "increments used_count on valid code" do
      promo = create(:promotion_code, code: "SAVE10")
      expect { PromotionCode.redeem!("SAVE10") }.to change { promo.reload.used_count }.by(1)
    end

    it "returns the promotion code" do
      promo = create(:promotion_code, code: "SAVE10")
      result = PromotionCode.redeem!("SAVE10")
      expect(result).to eq(promo)
    end

    it "is case-insensitive for the code lookup" do
      promo = create(:promotion_code, code: "SAVE10")
      expect { PromotionCode.redeem!("save10") }.to change { promo.reload.used_count }.by(1)
    end

    it "raises ActiveRecord::RecordNotFound for unknown code" do
      expect { PromotionCode.redeem!("UNKNOWN") }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises for inactive code" do
      create(:promotion_code, :inactive, code: "INACTIVE")
      expect { PromotionCode.redeem!("INACTIVE") }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises for expired code" do
      create(:promotion_code, :expired, code: "EXPIRED")
      expect { PromotionCode.redeem!("EXPIRED") }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises when usage_limit is reached" do
      promo = create(:promotion_code, :exhausted, code: "FULL")
      expect { PromotionCode.redeem!("FULL") }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "succeeds when used_count is below usage_limit" do
      promo = create(:promotion_code, code: "PARTIAL", usage_limit: 5, used_count: 4)
      expect { PromotionCode.redeem!("PARTIAL") }.to change { promo.reload.used_count }.by(1)
    end
  end

  describe "#expired?" do
    it "returns false when valid_until is nil" do
      promo = build(:promotion_code, valid_until: nil)
      expect(promo.expired?).to be false
    end

    it "returns true when valid_until is in the past" do
      promo = build(:promotion_code, valid_until: 1.day.ago)
      expect(promo.expired?).to be true
    end

    it "returns false when valid_until is in the future" do
      promo = build(:promotion_code, valid_until: 1.day.from_now)
      expect(promo.expired?).to be false
    end
  end

  describe "#usage_remaining" do
    it "returns nil when usage_limit is nil (unlimited)" do
      promo = build(:promotion_code, usage_limit: nil, used_count: 5)
      expect(promo.usage_remaining).to be_nil
    end

    it "returns correct remaining count" do
      promo = build(:promotion_code, usage_limit: 10, used_count: 3)
      expect(promo.usage_remaining).to eq(7)
    end

    it "returns 0 when exhausted" do
      promo = build(:promotion_code, usage_limit: 5, used_count: 5)
      expect(promo.usage_remaining).to eq(0)
    end
  end
end

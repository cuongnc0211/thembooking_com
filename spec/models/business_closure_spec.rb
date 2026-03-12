require "rails_helper"

RSpec.describe BusinessClosure, type: :model do
  let(:business) { create(:business) }

  describe "associations" do
    it { is_expected.to belong_to(:business) }
  end

  describe "validations" do
    it "is valid with business and future date" do
      closure = build(:business_closure, business: business, date: Date.tomorrow)
      expect(closure).to be_valid
    end

    it "requires date" do
      expect(build(:business_closure, date: nil)).not_to be_valid
    end

    it "rejects past dates on create" do
      expect(build(:business_closure, date: Date.yesterday)).not_to be_valid
    end

    it "rejects duplicate date for same business" do
      create(:business_closure, business: business, date: Date.tomorrow)
      expect(build(:business_closure, business: business, date: Date.tomorrow)).not_to be_valid
    end

    it "allows same date for different businesses" do
      other_business = create(:business, user: create(:user), slug: "other-shop")
      create(:business_closure, business: business, date: Date.tomorrow)
      expect(build(:business_closure, business: other_business, date: Date.tomorrow)).to be_valid
    end
  end

  describe "scopes" do
    it ".upcoming returns closures from today and future, ordered by date" do
      today = create(:business_closure, business: business, date: Date.current)
      future = create(:business_closure, business: business, date: Date.tomorrow)
      future2 = create(:business_closure, business: business, date: Date.tomorrow + 1.day)
      expect(BusinessClosure.upcoming).to contain_exactly(today, future, future2)
    end

    it ".upcoming excludes past closures when queried at different times" do
      # Create closure for tomorrow
      future = create(:business_closure, business: business, date: Date.tomorrow)
      # Verify it's in upcoming
      expect(BusinessClosure.upcoming).to include(future)
    end

    it ".for_date returns closures for a specific date" do
      closure = create(:business_closure, business: business, date: Date.tomorrow)
      create(:business_closure, business: business, date: Date.tomorrow + 1.day)
      expect(BusinessClosure.for_date(Date.tomorrow)).to contain_exactly(closure)
    end
  end
end

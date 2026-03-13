require "rails_helper"

RSpec.describe BusinessClosure, type: :model do
  let(:branch) { create(:branch) }

  describe "associations" do
    it { is_expected.to belong_to(:branch) }
  end

  describe "validations" do
    it "is valid with branch and future date" do
      closure = build(:business_closure, branch: branch, date: Date.tomorrow)
      expect(closure).to be_valid
    end

    it "requires date" do
      expect(build(:business_closure, date: nil)).not_to be_valid
    end

    it "rejects past dates on create" do
      expect(build(:business_closure, date: Date.yesterday)).not_to be_valid
    end

    it "rejects duplicate date for same branch" do
      create(:business_closure, branch: branch, date: Date.tomorrow)
      expect(build(:business_closure, branch: branch, date: Date.tomorrow)).not_to be_valid
    end

    it "allows same date for different branches" do
      other_branch = create(:branch)
      create(:business_closure, branch: branch, date: Date.tomorrow)
      expect(build(:business_closure, branch: other_branch, date: Date.tomorrow)).to be_valid
    end
  end

  describe "scopes" do
    it ".upcoming returns closures from today and future, ordered by date" do
      today   = create(:business_closure, branch: branch, date: Date.current)
      future  = create(:business_closure, branch: branch, date: Date.tomorrow)
      future2 = create(:business_closure, branch: branch, date: Date.tomorrow + 1.day)
      expect(BusinessClosure.upcoming).to contain_exactly(today, future, future2)
    end

    it ".upcoming excludes past closures when queried at different times" do
      future = create(:business_closure, branch: branch, date: Date.tomorrow)
      expect(BusinessClosure.upcoming).to include(future)
    end

    it ".for_date returns closures for a specific date" do
      closure = create(:business_closure, branch: branch, date: Date.tomorrow)
      create(:business_closure, branch: branch, date: Date.tomorrow + 1.day)
      expect(BusinessClosure.for_date(Date.tomorrow)).to contain_exactly(closure)
    end
  end
end

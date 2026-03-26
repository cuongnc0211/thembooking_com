require "rails_helper"

RSpec.describe ServiceCategory, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:branch) }
    it { is_expected.to have_many(:services) }
  end

  describe "validations" do
    subject { build(:service_category) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(100) }

    it "validates uniqueness of name scoped to branch" do
      existing = create(:service_category, name: "Hair")
      duplicate = build(:service_category, name: "Hair", branch: existing.branch)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to be_present
    end

    it "allows same name in different branches" do
      create(:service_category, name: "Hair")
      other = build(:service_category, name: "Hair", branch: create(:branch))
      expect(other).to be_valid
    end
  end

  describe "dependent nullify on services" do
    it "sets service_category_id to nil on services when category is destroyed" do
      category = create(:service_category)
      service = create(:service, branch: category.branch, service_category: category)

      expect { category.destroy }.not_to change(Service, :count)
      expect(service.reload.service_category_id).to be_nil
    end
  end

  describe "scopes" do
    describe ".ordered" do
      it "returns categories ordered by position then name" do
        branch = create(:branch)
        b = create(:service_category, branch: branch, name: "B Category", position: 1)
        a = create(:service_category, branch: branch, name: "A Category", position: 2)
        c = create(:service_category, branch: branch, name: "C Category", position: 1)

        expect(branch.service_categories.ordered).to eq([ b, c, a ])
      end
    end
  end
end

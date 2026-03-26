require "rails_helper"

RSpec.describe Staff, type: :model do
  describe "associations" do
    it { should have_many(:admin_sessions).dependent(:destroy) }
  end

  describe "validations" do
    subject { build(:staff) }

    it { should validate_presence_of(:email_address) }
    it { should validate_uniqueness_of(:email_address).case_insensitive }
    it { should validate_presence_of(:name) }
  end

  describe "enums" do
    it { should define_enum_for(:role).with_values(super_admin: 0, developer: 1, sale: 2, accountant: 3) }
  end

  describe "scopes" do
    it ".active returns only active staff" do
      active_staff = create(:staff, active: true)
      create(:staff, active: false)
      expect(Staff.active).to eq([ active_staff ])
    end
  end

  describe "authentication" do
    it "authenticates with correct password" do
      staff = create(:staff, password: "securepass1", password_confirmation: "securepass1")
      expect(Staff.authenticate_by(email_address: staff.email_address, password: "securepass1")).to eq(staff)
    end

    it "returns nil with wrong password" do
      staff = create(:staff)
      expect(Staff.authenticate_by(email_address: staff.email_address, password: "wrongpassword")).to be_nil
    end
  end

  describe "email normalization" do
    it "strips and downcases email" do
      staff = create(:staff, email_address: "  Test@Example.COM  ")
      expect(staff.email_address).to eq("test@example.com")
    end
  end
end

require "rails_helper"

RSpec.describe Dashboard::OnboardingHelper, type: :helper do
  describe "#step_description" do
    it "returns correct description for step 1" do
      expect(helper.step_description(1)).to eq("Tell us a bit about yourself")
    end

    it "returns correct description for step 2" do
      expect(helper.step_description(2)).to eq("Set up your business profile")
    end

    it "returns correct description for step 3" do
      expect(helper.step_description(3)).to eq("When are you open for business?")
    end

    it "returns correct description for step 4" do
      expect(helper.step_description(4)).to eq("Add at least one service to get started")
    end
  end

  describe "#step_name" do
    it "returns correct name for step 1" do
      expect(helper.step_name(1)).to eq("Your Information")
    end

    it "returns correct name for step 2" do
      expect(helper.step_name(2)).to eq("Business Details")
    end

    it "returns correct name for step 3" do
      expect(helper.step_name(3)).to eq("Operating Hours")
    end

    it "returns correct name for step 4" do
      expect(helper.step_name(4)).to eq("Services")
    end
  end

  describe "#step_circle_class" do
    it "returns completed class when step is completed" do
      result = helper.step_circle_class(true, false)
      expect(result).to include("bg-primary-500")
      expect(result).to include("text-white")
    end

    it "returns current class when step is current" do
      result = helper.step_circle_class(false, true)
      expect(result).to include("bg-primary-100")
      expect(result).to include("text-primary-600")
      expect(result).to include("border-primary-500")
    end

    it "returns upcoming class when step is upcoming" do
      result = helper.step_circle_class(false, false)
      expect(result).to include("bg-slate-100")
      expect(result).to include("text-slate-400")
    end

    it "includes base classes" do
      result = helper.step_circle_class(false, false)
      expect(result).to include("w-10")
      expect(result).to include("h-10")
      expect(result).to include("rounded-full")
      expect(result).to include("flex")
      expect(result).to include("items-center")
      expect(result).to include("justify-center")
    end
  end
end
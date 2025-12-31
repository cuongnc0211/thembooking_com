require "rails_helper"

RSpec.describe "Onboarding Flow", type: :system do
  let(:user) { create(:user, onboarding_step: 1, name: nil, phone: nil) }

  before do
    driven_by(:rack_test)
    visit new_session_path
    fill_in "Email", with: user.email_address
    fill_in "Password", with: "password123"
    click_button "Sign in"
  end

  describe "complete onboarding journey" do
    it "walks through all 4 steps successfully" do
      # Should be redirected to onboarding automatically
      visit dashboard_onboarding_path

      # Step 1: User Info
      expect(page).to have_content("Step 1")
      expect(page).to have_content("Your Information")
      fill_in "Your Name", with: "Nguyen Van A"
      fill_in "Phone Number", with: "0901234567"
      click_button "Continue"

      # Step 2: Business
      expect(page).to have_content("Step 2")
      expect(page).to have_content("Your Business")
      fill_in "Business Name", with: "Toc Dep Salon"
      select "Salon", from: "Type of Business"
      fill_in "thembooking.com/", with: "toc-dep-salon"
      fill_in "Business Phone", with: "0901234567"
      fill_in "How many customers can you serve at once?", with: "3"
      fill_in "Address", with: "123 Nguyen Hue, Q1, TP.HCM"
      click_button "Continue"

      # Step 3: Hours
      expect(page).to have_content("Step 3")
      expect(page).to have_content("Operating Hours")
      check "Weekdays (Mon-Fri)"
      check "Saturday"
      click_button "Continue"

      # Step 4: Services
      expect(page).to have_content("Step 4")
      expect(page).to have_content("Your Services")
      fill_in "Service Name", with: "Haircut"
      select "30 min", from: "Duration"
      fill_in "VND", with: "80000"
      click_button "Complete Setup"

      # Completed and redirected to dashboard
      expect(page).to have_current_path(dashboard_root_path)
      expect(page).to have_content("Setup complete! Your booking page is ready.")

      # Verify data was saved correctly
      user.reload
      expect(user.onboarding_completed?).to be true
      expect(user.name).to eq("Nguyen Van A")
      expect(user.phone).to eq("0901234567")
      expect(user.business).to be_present
      expect(user.business.name).to eq("Toc Dep Salon")
      expect(user.business.slug).to eq("toc-dep-salon")
      expect(user.business.services.count).to eq(1)
      expect(user.business.services.first.name).to eq("Haircut")
    end
  end

  describe "progress bar navigation" do
    before do
      user.update!(onboarding_step: 3, name: "John", phone: "0901234567")
      create(:business, user: user)
      visit dashboard_onboarding_path
    end

    it "shows completed steps as clickable links" do
      expect(page).to have_link("You", href: dashboard_onboarding_path(step: 1))
      expect(page).to have_link("Business", href: dashboard_onboarding_path(step: 2))
    end

    it "allows navigating back to step 1" do
      click_link "You"
      expect(page).to have_content("Step 1")
      expect(page).to have_content("Your Information")
    end

    it "allows navigating back to step 2" do
      click_link "Business"
      expect(page).to have_content("Step 2")
      expect(page).to have_content("Your Business")
    end

    it "shows current step as highlighted" do
      expect(page).to have_css(".text-primary-600", text: "Hours")
    end

    it "shows future steps as disabled" do
      expect(page).to have_css(".text-slate-400", text: "Services")
    end
  end

  describe "form validation" do
    it "validates required fields in step 1" do
      visit dashboard_onboarding_path

      # Try to continue without filling required fields
      click_button "Continue"

      # Should still be on step 1 (validation failed)
      expect(page).to have_content("Step 1")
      expect(page).to have_content("can't be blank")
    end

    it "validates required fields in step 2" do
      # Complete step 1 first
      user.update!(name: "John", phone: "0901234567")
      visit dashboard_onboarding_path

      fill_in "Business Name", with: "" # Empty required field
      click_button "Continue"

      # Should still be on step 2 (validation failed)
      expect(page).to have_content("Step 2")
      expect(page).to have_content("can't be blank")
    end

    it "validates at least one service in step 4" do
      # Complete first 3 steps
      user.update!(name: "John", phone: "0901234567")
      create(:business, user: user)
      visit dashboard_onboarding_path

      # Skip to step 4
      visit dashboard_onboarding_path(step: 4)

      # Try to complete without adding any services
      click_button "Complete Setup"

      # Should still be on step 4 with validation error
      expect(page).to have_content("Step 4")
    end
  end

  describe "resume after logout" do
    it "resumes at correct step after re-login" do
      # Complete step 1
      fill_in "Your Name", with: "John"
      fill_in "Phone Number", with: "0901234567"
      click_button "Continue"

      expect(page).to have_content("Step 2")

      # Logout
      visit session_path
      click_button "Sign out"

      # Re-login
      visit new_session_path
      fill_in "Email", with: user.email_address
      fill_in "Password", with: "password123"
      click_button "Sign in"

      visit dashboard_onboarding_path
      expect(page).to have_content("Step 2")
      expect(user.reload.name).to eq("John")
    end
  end

  describe "step navigation limits" do
    before do
      user.update!(onboarding_step: 2, name: "John", phone: "0901234567")
      visit dashboard_onboarding_path
    end

    it "blocks access to future steps via direct URL" do
      visit dashboard_onboarding_path(step: 4)
      expect(page).to have_current_path(dashboard_onboarding_path)
      expect(page).to have_content("Complete previous steps first")
    end

    it "allows editing previous steps without changing progress" do
      visit dashboard_onboarding_path(step: 1)

      fill_in "Your Name", with: "Jane Doe"
      click_button "Continue"

      expect(user.reload.name).to eq("Jane Doe")
      expect(user.onboarding_step).to eq(2) # unchanged
    end
  end

  describe "dashboard access control" do
    context "when onboarding incomplete" do
      before do
        user.update!(onboarding_step: 2, name: "John", phone: "0901234567")
        visit dashboard_root_path
      end

      it "redirects to onboarding from dashboard root" do
        expect(page).to have_current_path(dashboard_onboarding_path)
      end

      it "redirects to onboarding from profile edit" do
        visit edit_dashboard_profile_path
        expect(page).to have_current_path(dashboard_onboarding_path)
      end
    end

    context "when onboarding completed" do
      let(:completed_user) { create(:user, :fully_onboarded) }

      before do
        visit new_session_path
        fill_in "Email", with: completed_user.email_address
        fill_in "Password", with: "password123"
        click_button "Sign in"
      end

      it "allows access to dashboard root" do
        visit dashboard_root_path
        expect(page).to have_current_path(dashboard_root_path)
        expect(page).to have_http_status(:success)
      end

      it "redirects onboarding to dashboard" do
        visit dashboard_onboarding_path
        expect(page).to have_current_path(dashboard_root_path)
      end
    end
  end

  describe "business slug generation" do
    it "accepts custom slug" do
      user.update!(name: "John", phone: "0901234567")
      visit dashboard_onboarding_path

      fill_in "Business Name", with: "My Awesome Shop"
      fill_in "thembooking.com/", with: "my-awesome-shop-123"
      click_button "Continue"

      expect(user.reload.business.slug).to eq("my-awesome-shop-123")
    end
  end

  describe "operating hours setup" do
    before do
      user.update!(name: "John", phone: "0901234567")
      create(:business, user: user)
      visit dashboard_onboarding_path(step: 3)
    end

    it "saves weekday hours correctly" do
      check "Weekdays (Mon-Fri)"
      fill_in "operating_hours[weekdays][open]", with: "09:00"
      fill_in "operating_hours[weekdays][close]", with: "18:00"
      click_button "Continue"

      user.reload
      expect(user.business.operating_hours["monday"]["open"]).to eq("09:00")
      expect(user.business.operating_hours["monday"]["close"]).to eq("18:00")
      expect(user.business.operating_hours["monday"]["closed"]).to be false
    end

    it "saves weekend hours correctly" do
      check "Saturday"
      check "Sunday"
      fill_in "operating_hours[saturday][open]", with: "10:00"
      fill_in "operating_hours[saturday][close]", with: "16:00"
      fill_in "operating_hours[sunday][open]", with: "11:00"
      fill_in "operating_hours[sunday][close]", with: "15:00"
      click_button "Continue"

      user.reload
      expect(user.business.operating_hours["saturday"]["open"]).to eq("10:00")
      expect(user.business.operating_hours["sunday"]["open"]).to eq("11:00")
    end

    it "saves closed days correctly" do
      uncheck "Weekdays (Mon-Fri)"
      uncheck "Saturday"
      uncheck "Sunday"
      click_button "Continue"

      # This should fail validation - at least one day must be open
      expect(page).to have_content("Step 3")
      expect(page).to have_content("at least one day")
    end
  end

  # Note: JavaScript toggle behavior tests would require selenium-webdriver gem
  # The toggle functionality is implemented via Stimulus controller
  # Manual testing required to verify:
  # 1. Unchecking Saturday/Sunday disables their time fields
  # 2. Expanding weekdays and unchecking individual days (Mon-Fri) disables their time fields
  # 3. Re-checking re-enables the time fields

  describe "error handling" do
    it "handles business slug conflicts gracefully" do
      # Create existing business with same slug
      create(:business, slug: "existing-shop")

      user.update!(name: "John", phone: "0901234567")
      visit dashboard_onboarding_path

      fill_in "Business Name", with: "My Shop"
      fill_in "thembooking.com/", with: "existing-shop"
      click_button "Continue"

      expect(page).to have_content("Step 2")
      expect(page).to have_content("has already been taken")
    end

    it "handles invalid email format" do
      visit new_session_path
      fill_in "Email", with: "invalid-email"
      fill_in "Password", with: "password123"
      click_button "Sign in"

      expect(page).to have_content("Invalid email or password")
    end
  end
end

require 'rails_helper'

RSpec.describe 'User Sign In', type: :system do
  let(:user) { create(:user, email_address: 'test@example.com', password: 'password123') }

  before do
    driven_by :selenium_chrome_headless
  end

  describe 'successful sign in' do
    it 'signs in with valid credentials', :smoke do
      visit new_session_path

      expect(page).to have_content('Sign in')

      fill_in 'Email', with: user.email_address
      fill_in 'Password', with: 'password123'

      click_button 'Sign in'

      expect(page).to have_current_path(root_path, ignore_query: true)
      expect_to_be_signed_in
    end
  end

  describe 'failed sign in' do
    it 'shows error with invalid email' do
      visit new_session_path

      fill_in 'Email', with: 'wrong@example.com'
      fill_in 'Password', with: 'password123'

      click_button 'Sign in'

      expect(page).to have_content('Invalid')
      expect_to_be_signed_out
    end

    it 'shows error with invalid password' do
      visit new_session_path

      fill_in 'Email', with: user.email_address
      fill_in 'Password', with: 'wrong_password'

      click_button 'Sign in'

      expect(page).to have_content('Invalid')
      expect_to_be_signed_out
    end
  end

  describe 'sign out' do
    it 'signs out successfully' do
      sign_in_as(user)
      expect_to_be_signed_in

      click_link 'Sign out'

      expect_to_be_signed_out
      expect(page).to have_current_path(root_path, ignore_query: true)
    end
  end

  describe 'redirect after sign in' do
    it 'redirects to requested page after sign in' do
      # Try to access protected page while signed out
      visit dashboard_profile_path

      # Should redirect to sign in
      expect(page).to have_current_path(new_session_path)

      # Sign in
      fill_in 'Email', with: user.email_address
      fill_in 'Password', with: 'password123'
      click_button 'Sign in'

      # Should redirect back to originally requested page
      expect(page).to have_current_path(dashboard_profile_path, ignore_query: true)
    end
  end

  describe 'page object pattern usage' do
    let(:sign_in_page) { PageObjects::SignInPage.new }

    it 'signs in successfully using page object' do
      sign_in_page.visit_page
                  .sign_in_with(email: user.email_address, password: 'password123')

      expect(sign_in_page).to be_signed_in
    end

    it 'shows error with invalid credentials using page object' do
      sign_in_page.visit_page
                  .sign_in_with(email: 'wrong@example.com', password: 'wrong')

      expect(sign_in_page).to have_error_message('Invalid')
      expect(sign_in_page).to be_signed_out
    end
  end

  describe 'custom matchers' do
    it 'uses be_signed_in matcher' do
      sign_in_as(user)

      expect(page).to be_signed_in
    end
  end
end

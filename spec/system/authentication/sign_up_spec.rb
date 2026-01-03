require 'rails_helper'

RSpec.describe 'User Sign Up', type: :system do
  before do
    driven_by :selenium_chrome_headless
  end

  describe 'successful sign up' do
    it 'creates new user account with valid credentials', :smoke do
      visit new_registration_path

      # Use field names instead of labels to avoid translation issues
      fill_in 'user[email_address]', with: 'newuser@example.com'
      fill_in 'user[password]', with: 'secure_password123'
      fill_in 'user[password_confirmation]', with: 'secure_password123'

      expect {
        find('input[type="submit"]').click # Use generic submit button selector
      }.to change(User, :count).by(1)

      # Verify user attributes
      user = User.last
      expect(user.email_address).to eq('newuser@example.com')
    end
  end

  describe 'failed sign up - validation errors' do
    it 'shows error when email is already taken' do
      existing_user = create(:user, email_address: 'taken@example.com')

      visit new_registration_path

      fill_in 'Email', with: 'taken@example.com'
      fill_in 'Password', with: 'password123'
      fill_in 'Password confirmation', with: 'password123'

      expect {
        click_button 'Sign up'
      }.not_to change(User, :count)

      expect(page).to have_content('has already been taken')
    end

    it 'shows error when password confirmation does not match' do
      visit new_registration_path

      fill_in 'Email', with: 'user@example.com'
      fill_in 'Password', with: 'password123'
      fill_in 'Password confirmation', with: 'different_password'

      click_button 'Sign up'

      expect(page).to have_content("doesn't match")
    end

    it 'shows error when password is too short' do
      visit new_registration_path

      fill_in 'Email', with: 'user@example.com'
      fill_in 'Password', with: '123'
      fill_in 'Password confirmation', with: '123'

      click_button 'Sign up'

      expect(page).to have_content('is too short')
    end

    it 'shows error when required fields are blank' do
      visit new_registration_path

      # Leave all fields empty
      click_button 'Sign up'

      expect(page).to have_content("can't be blank")
    end
  end

  describe 'page object pattern usage' do
    let(:sign_up_page) { PageObjects::SignUpPage.new }

    it 'signs up successfully using page object' do
      sign_up_page.visit_page
                  .sign_up_with(
                    email: 'newuser@example.com',
                    password: 'password123'
                  )

      expect(User.last.email_address).to eq('newuser@example.com')
    end

    it 'shows email taken error using page object' do
      create(:user, email_address: 'taken@example.com')

      sign_up_page.visit_page
                  .sign_up_with(email: 'taken@example.com', password: 'password123')

      expect(sign_up_page).to have_email_taken_error
    end
  end
end

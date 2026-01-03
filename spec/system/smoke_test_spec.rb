require 'rails_helper'

RSpec.describe 'System Test Setup', type: :system do
  it 'can visit the home page' do
    visit root_path

    expect(page).to have_content('ThemBooking')
    # Note: page.status_code not supported by Selenium driver
  end

  it 'uses headless Chrome driver' do
    expect(Capybara.current_driver).to eq(:selenium_chrome_headless)
  end

  it 'can fill in forms and click buttons' do
    visit new_session_path

    fill_in 'Email', with: 'test@example.com'
    fill_in 'Password', with: 'password123'

    # Don't submit - just verify selectors work
    expect(page).to have_field('Email', with: 'test@example.com')
    expect(page).to have_button('Sign in')
  end

  it 'cleans database between tests' do
    # This test should start with clean database
    expect(User.count).to eq(0)

    create(:user)
    expect(User.count).to eq(1)
  end

  it 'cleans database after previous test' do
    # Verify database_cleaner worked
    expect(User.count).to eq(0)
  end
end

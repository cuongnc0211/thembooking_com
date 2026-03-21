module SystemAuthenticationHelpers
  # Browser-based sign in for system tests
  def sign_in_as(user, password: 'password123')
    visit new_session_path

    fill_in 'Email', with: user.email_address
    fill_in 'Password', with: password
    click_button 'Sign in'

    # Wait for redirect to complete (path depends on onboarding status)
    expect(page).not_to have_current_path(new_session_path, ignore_query: true)
  end

  def sign_out_via_ui
    click_button 'Sign out'
  end

  # Expectation helpers
  def expect_to_be_signed_in
    # Verify signed-in state by checking for sign-out button (button_to in layouts)
    expect(page).to have_button('Sign out')
  end

  def expect_to_be_signed_out
    expect(page).to have_link('Sign in')
  end

  # Flash message helpers
  def expect_flash_notice(message)
    within('.flash.notice, .alert.alert-success, [role="alert"]') do
      expect(page).to have_content(message)
    end
  end

  def expect_flash_alert(message)
    within('.flash.alert, .alert.alert-danger, [role="alert"]') do
      expect(page).to have_content(message)
    end
  end
end

RSpec.configure do |config|
  config.include SystemAuthenticationHelpers, type: :system
end

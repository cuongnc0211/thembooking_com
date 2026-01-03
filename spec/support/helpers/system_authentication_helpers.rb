module SystemAuthenticationHelpers
  # Browser-based sign in for system tests
  def sign_in_as(user, password: 'password123')
    visit new_session_path

    fill_in 'Email', with: user.email_address
    fill_in 'Password', with: password
    click_button 'Sign in'

    # Wait for redirect to complete
    expect(page).to have_current_path(root_path, ignore_query: true)
  end

  def sign_out_via_ui
    click_link 'Sign out'
  end

  # Expectation helpers
  def expect_to_be_signed_in
    # Verify signed-in state by checking for sign-out link
    expect(page).to have_link('Sign out')
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

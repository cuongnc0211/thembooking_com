module PageObjects
  class SignInPage < BasePage
    def visit_page
      visit new_session_path
      self
    end

    def sign_in_with(email:, password:, remember_me: false)
      fill_in 'Email', with: email
      fill_in 'Password', with: password
      check 'Remember me' if remember_me && has_field?('Remember me')
      click_button 'Sign in'
      self
    end

    def has_error_message?(message)
      has_flash_alert?(message)
    end

    def has_success_message?(message)
      has_flash_notice?(message)
    end

    def signed_in?
      has_link?('Sign out')
    end

    def signed_out?
      has_link?('Sign in')
    end
  end
end

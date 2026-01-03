module PageObjects
  class SignUpPage < BasePage
    def visit_page
      visit new_registration_path
      self
    end

    def sign_up_with(email:, password:, password_confirmation: nil, **additional_fields)
      fill_in 'Email', with: email
      fill_in 'Password', with: password
      fill_in 'Password confirmation', with: password_confirmation || password

      # Handle additional fields dynamically (e.g., name, phone)
      additional_fields.each do |field, value|
        fill_in field.to_s.titleize, with: value
      end

      click_button 'Sign up'
      self
    end

    def has_email_taken_error?
      has_validation_error?('email', 'has already been taken')
    end

    def has_password_mismatch_error?
      has_validation_error?('password_confirmation', "doesn't match") ||
        has_content?("Password confirmation doesn't match")
    end

    def has_password_too_short_error?
      has_validation_error?('password', 'is too short') ||
        has_content?('Password is too short')
    end
  end
end

module PageObjects
  class BasePage
    include Capybara::DSL
    include RSpec::Matchers
    include Rails.application.routes.url_helpers

    def initialize
      # Subclasses can override
    end

    # Common utility methods
    def has_flash_notice?(message)
      within('.flash.notice, .alert.alert-success, [role="alert"]') do
        has_content?(message)
      end
    rescue Capybara::ElementNotFound
      false
    end

    def has_flash_alert?(message)
      within('.flash.alert, .alert.alert-danger, [role="alert"]') do
        has_content?(message)
      end
    rescue Capybara::ElementNotFound
      false
    end

    def has_validation_error?(field, message)
      within(".field_with_errors [name*='#{field}'], .invalid-feedback, .error") do
        has_content?(message)
      end
    rescue Capybara::ElementNotFound
      false
    end
  end
end

require 'capybara/rspec'
require 'selenium-webdriver'

# Selenium 4+ has built-in driver management - no need for webdrivers gem

# Capybara global configuration
Capybara.configure do |config|
  # Wait up to 5 seconds for elements to appear
  config.default_max_wait_time = 5

  # Default driver for non-JS tests (fast)
  config.default_driver = :rack_test

  # Driver for JavaScript-enabled tests
  config.javascript_driver = :selenium_chrome_headless
end

# Chrome headless driver (for CI and local headless testing)
Capybara.register_driver :selenium_chrome_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new

  options.add_argument('--headless')
  options.add_argument('--disable-gpu')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  options.add_argument('--window-size=1400,1400')

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

# Chrome visible driver (for debugging - shows browser)
Capybara.register_driver :selenium_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--window-size=1400,1400')

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

# Server configuration
Capybara.server = :puma, { Silent: true }

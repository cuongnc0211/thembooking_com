# Guide: Integration/System Testing cho Rails Monolith với RSpec

## Mục lục
1. [Setup cơ bản](#1-setup-cơ-bản)
2. [Cấu hình Capybara và Selenium](#2-cấu-hình-capybara-và-selenium)
3. [Viết System Tests cho Authentication](#3-viết-system-tests-cho-authentication)
4. [Best Practices](#4-best-practices)
5. [Debugging và Troubleshooting](#5-debugging-và-troubleshooting)

---

## 1. Setup cơ bản

### 1.1. Cài đặt gems

Thêm vào `Gemfile` trong group `:test`:

```ruby
group :test do
  # System testing
  gem 'capybara'
  gem 'selenium-webdriver'
  gem 'webdrivers' # Auto-download và update browser drivers
  
  # Optional nhưng rất hữu ích
  gem 'shoulda-matchers' # Matchers bổ sung
  gem 'database_cleaner-active_record' # Clean database giữa các tests
  gem 'faker' # Generate fake data
  gem 'launchy' # Debug bằng cách mở browser
end
```

Chạy:
```bash
bundle install
```

### 1.2. Cấu trúc thư mục

```
spec/
├── rails_helper.rb
├── spec_helper.rb
├── support/
│   ├── capybara.rb
│   ├── database_cleaner.rb
│   └── helpers/
│       └── authentication_helpers.rb
├── factories/
│   └── users.rb
├── models/
├── requests/ # Integration tests (controller level)
└── system/   # System tests (browser level - E2E)
    └── authentication/
        ├── sign_up_spec.rb
        └── sign_in_spec.rb
```

---

## 2. Cấu hình Capybara và Selenium

### 2.1. Tạo `spec/support/capybara.rb`

```ruby
# spec/support/capybara.rb
require 'capybara/rspec'
require 'selenium-webdriver'

# Cấu hình Capybara
Capybara.configure do |config|
  config.default_max_wait_time = 5 # Đợi tối đa 5s cho element xuất hiện
  config.default_driver = :rack_test # Driver mặc định (nhanh, không JS)
  config.javascript_driver = :selenium_chrome_headless # Driver cho JS tests
end

# Cấu hình Chrome headless (chạy ngầm, không mở browser)
Capybara.register_driver :selenium_chrome_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  
  options.add_argument('--headless') # Chạy ngầm
  options.add_argument('--disable-gpu')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  options.add_argument('--window-size=1400,1400')
  
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

# Driver để debug - mở browser thật
Capybara.register_driver :selenium_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--window-size=1400,1400')
  
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

# Server configuration
Capybara.server = :puma, { Silent: true }
```

### 2.2. Cấu hình Database Cleaner

Tạo `spec/support/database_cleaner.rb`:

```ruby
# spec/support/database_cleaner.rb
require 'database_cleaner/active_record'

RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end

  # System tests cần truncation vì chạy trong thread riêng
  config.before(:each, type: :system) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end
```

### 2.3. Enable support files trong `rails_helper.rb`

```ruby
# spec/rails_helper.rb

# Uncomment dòng này nếu đang bị comment
Dir[Rails.root.join('spec/support/**/*.rb')].sort.each { |f| require f }

RSpec.configure do |config|
  # System test configuration
  config.before(:each, type: :system) do
    driven_by :selenium_chrome_headless
  end
  
  # Nếu muốn debug, dùng driver có UI
  # config.before(:each, type: :system) do
  #   driven_by :selenium_chrome
  # end
end
```

---

## 3. Viết System Tests cho Authentication

### 3.1. Setup Factory cho User

Tạo `spec/factories/users.rb`:

```ruby
# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    password { 'password123' }
    password_confirmation { 'password123' }
    
    # Nếu có confirmed_at field (Devise confirmable)
    # confirmed_at { Time.current }
    
    trait :unconfirmed do
      confirmed_at { nil }
    end
  end
end
```

### 3.2. Authentication Helpers

Tạo `spec/support/helpers/authentication_helpers.rb`:

```ruby
# spec/support/helpers/authentication_helpers.rb
module AuthenticationHelpers
  # Helper để sign in trong system tests
  def sign_in_as(user)
    visit new_user_session_path # hoặc route đăng nhập của bạn
    
    fill_in 'Email', with: user.email
    fill_in 'Password', with: user.password
    click_button 'Đăng nhập'
  end
  
  # Helper để check đã login
  def expect_to_be_signed_in
    expect(page).to have_content('Đăng xuất')
    # hoặc check element khác chỉ xuất hiện khi logged in
  end
  
  def expect_to_be_signed_out
    expect(page).to have_content('Đăng nhập')
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelpers, type: :system
end
```

### 3.3. System Test - Sign Up Flow

Tạo `spec/system/authentication/sign_up_spec.rb`:

```ruby
# spec/system/authentication/sign_up_spec.rb
require 'rails_helper'

RSpec.describe 'User Sign Up', type: :system do
  before do
    driven_by :selenium_chrome_headless
  end

  describe 'Successful sign up' do
    it 'allows user to create account with valid credentials' do
      visit new_user_registration_path
      
      expect(page).to have_content('Đăng ký')
      
      fill_in 'Email', with: 'newuser@example.com'
      fill_in 'Password', with: 'secure_password123'
      fill_in 'Password confirmation', with: 'secure_password123'
      
      # Nếu có thêm fields khác
      # fill_in 'Name', with: 'John Doe'
      
      expect {
        click_button 'Đăng ký'
      }.to change(User, :count).by(1)
      
      # Verify redirect và flash message
      expect(page).to have_content('Đăng ký thành công')
      expect(current_path).to eq(root_path) # hoặc dashboard_path
      
      # Verify user được tạo đúng
      user = User.last
      expect(user.email).to eq('newuser@example.com')
    end
  end

  describe 'Failed sign up' do
    it 'shows errors when email is already taken' do
      existing_user = create(:user, email: 'taken@example.com')
      
      visit new_user_registration_path
      
      fill_in 'Email', with: 'taken@example.com'
      fill_in 'Password', with: 'password123'
      fill_in 'Password confirmation', with: 'password123'
      
      expect {
        click_button 'Đăng ký'
      }.not_to change(User, :count)
      
      expect(page).to have_content('Email đã được sử dụng')
    end
    
    it 'shows errors when password confirmation does not match' do
      visit new_user_registration_path
      
      fill_in 'Email', with: 'user@example.com'
      fill_in 'Password', with: 'password123'
      fill_in 'Password confirmation', with: 'different_password'
      
      click_button 'Đăng ký'
      
      expect(page).to have_content('Password confirmation không khớp')
    end
    
    it 'shows errors when password is too short' do
      visit new_user_registration_path
      
      fill_in 'Email', with: 'user@example.com'
      fill_in 'Password', with: '123'
      fill_in 'Password confirmation', with: '123'
      
      click_button 'Đăng ký'
      
      expect(page).to have_content('Password quá ngắn')
    end
  end

  describe 'Email confirmation flow', if: :confirmable_enabled do
    it 'sends confirmation email after sign up' do
      visit new_user_registration_path
      
      fill_in 'Email', with: 'newuser@example.com'
      fill_in 'Password', with: 'password123'
      fill_in 'Password confirmation', with: 'password123'
      
      expect {
        click_button 'Đăng ký'
      }.to change { ActionMailer::Base.deliveries.count }.by(1)
      
      expect(page).to have_content('Email xác nhận đã được gửi')
      
      # Verify email content
      mail = ActionMailer::Base.deliveries.last
      expect(mail.to).to include('newuser@example.com')
      expect(mail.subject).to match(/xác nhận|confirmation/i)
    end
  end
end
```

### 3.4. System Test - Sign In Flow

Tạo `spec/system/authentication/sign_in_spec.rb`:

```ruby
# spec/system/authentication/sign_in_spec.rb
require 'rails_helper'

RSpec.describe 'User Sign In', type: :system do
  let(:user) { create(:user, email: 'user@example.com', password: 'password123') }

  before do
    driven_by :selenium_chrome_headless
  end

  describe 'Successful sign in' do
    it 'allows user to sign in with valid credentials' do
      visit new_user_session_path
      
      expect(page).to have_content('Đăng nhập')
      
      fill_in 'Email', with: user.email
      fill_in 'Password', with: 'password123'
      
      click_button 'Đăng nhập'
      
      expect(page).to have_content('Đăng nhập thành công')
      expect(current_path).to eq(root_path) # hoặc dashboard_path
      expect_to_be_signed_in
    end
    
    it 'remembers user when "Remember me" is checked' do
      visit new_user_session_path
      
      fill_in 'Email', with: user.email
      fill_in 'Password', with: 'password123'
      check 'Remember me'
      
      click_button 'Đăng nhập'
      
      # Verify remember_me cookie được set
      expect(page.driver.browser.manage.cookie_named('remember_user_token')).to be_present
    end
  end

  describe 'Failed sign in' do
    it 'shows error with invalid email' do
      visit new_user_session_path
      
      fill_in 'Email', with: 'wrong@example.com'
      fill_in 'Password', with: 'password123'
      
      click_button 'Đăng nhập'
      
      expect(page).to have_content('Email hoặc password không đúng')
      expect(current_path).to eq(new_user_session_path)
      expect_to_be_signed_out
    end
    
    it 'shows error with invalid password' do
      visit new_user_session_path
      
      fill_in 'Email', with: user.email
      fill_in 'Password', with: 'wrong_password'
      
      click_button 'Đăng nhập'
      
      expect(page).to have_content('Email hoặc password không đúng')
      expect_to_be_signed_out
    end
  end

  describe 'Sign out' do
    it 'allows user to sign out' do
      sign_in_as(user)
      
      expect_to_be_signed_in
      
      click_link 'Đăng xuất' # hoặc click_button nếu là button
      
      expect(page).to have_content('Đăng xuất thành công')
      expect_to_be_signed_out
    end
  end

  describe 'Redirect after sign in' do
    it 'redirects to requested page after sign in' do
      visit bookings_path # Protected page
      
      # Should redirect to sign in
      expect(current_path).to eq(new_user_session_path)
      
      fill_in 'Email', with: user.email
      fill_in 'Password', with: 'password123'
      click_button 'Đăng nhập'
      
      # Should redirect back to bookings
      expect(current_path).to eq(bookings_path)
    end
  end
end
```

---

## 4. Best Practices

### 4.1. Page Objects Pattern

Để code sạch hơn, tạo Page Objects:

```ruby
# spec/support/page_objects/sign_in_page.rb
module PageObjects
  class SignInPage
    include Capybara::DSL
    
    def visit_page
      visit new_user_session_path
    end
    
    def sign_in(email:, password:, remember_me: false)
      fill_in 'Email', with: email
      fill_in 'Password', with: password
      check 'Remember me' if remember_me
      click_button 'Đăng nhập'
    end
    
    def has_error_message?(message)
      has_content?(message)
    end
  end
end

# Sử dụng trong spec:
RSpec.describe 'User Sign In', type: :system do
  let(:sign_in_page) { PageObjects::SignInPage.new }
  let(:user) { create(:user, password: 'password123') }
  
  it 'allows user to sign in' do
    sign_in_page.visit_page
    sign_in_page.sign_in(email: user.email, password: 'password123')
    
    expect(page).to have_content('Đăng nhập thành công')
  end
end
```

### 4.2. Shared Examples

Tạo shared examples cho các test cases tương tự:

```ruby
# spec/support/shared_examples/authentication.rb
RSpec.shared_examples 'requires authentication' do
  it 'redirects to sign in page' do
    visit path
    expect(current_path).to eq(new_user_session_path)
  end
end

# Sử dụng:
RSpec.describe 'Bookings page', type: :system do
  let(:path) { bookings_path }
  
  it_behaves_like 'requires authentication'
end
```

### 4.3. Custom Matchers

```ruby
# spec/support/matchers/authentication_matchers.rb
RSpec::Matchers.define :be_signed_in do
  match do |page|
    page.has_link?('Đăng xuất')
  end
  
  failure_message do
    'Expected user to be signed in, but found sign in link'
  end
end

# Sử dụng:
expect(page).to be_signed_in
```

### 4.4. Organize Tests với Tags

```ruby
RSpec.describe 'Authentication', type: :system do
  it 'successful sign in', :smoke do
    # Critical test, chạy trong smoke test suite
  end
  
  it 'handles rate limiting', :slow do
    # Test chậm, có thể skip trong local dev
  end
end

# Chạy chỉ smoke tests:
# rspec --tag smoke

# Skip slow tests:
# rspec --tag ~slow
```

---

## 5. Debugging và Troubleshooting

### 5.1. Screenshot khi test fail

Thêm vào `rails_helper.rb`:

```ruby
RSpec.configure do |config|
  config.after(:each, type: :system) do |example|
    if example.exception
      # Lưu screenshot
      meta = example.metadata
      filename = File.basename(meta[:file_path])
      line_number = meta[:line_number]
      
      screenshot_name = "screenshot-#{filename}-#{line_number}.png"
      screenshot_path = "tmp/screenshots/#{screenshot_name}"
      
      page.save_screenshot(screenshot_path)
      puts "Screenshot saved to: #{screenshot_path}"
      
      # Save page HTML
      html_path = screenshot_path.sub('.png', '.html')
      File.write(html_path, page.html)
      puts "HTML saved to: #{html_path}"
    end
  end
end
```

### 5.2. Debug với Launchy

```ruby
it 'does something' do
  visit some_path
  save_and_open_page # Mở browser với page hiện tại
  
  # hoặc
  save_and_open_screenshot # Mở screenshot
end
```

### 5.3. Pause execution để debug

```ruby
it 'does something' do
  visit some_path
  
  # Dừng lại để inspect
  binding.pry # hoặc debugger
  
  click_button 'Submit'
end
```

### 5.4. Show browser khi debug

```ruby
# Trong spec file
before do
  driven_by :selenium_chrome # Không headless
end

# Hoặc chỉ 1 test:
it 'does something', driver: :selenium_chrome do
  # ...
end
```

### 5.5. Common Issues

**Issue: Element not found**
```ruby
# Thay vì:
click_button 'Submit'

# Dùng:
find('button', text: 'Submit').click

# Hoặc wait:
expect(page).to have_button('Submit')
click_button 'Submit'
```

**Issue: Stale element**
```ruby
# Retry khi element bị stale
retries = 0
begin
  element = find('.dynamic-element')
  element.click
rescue Selenium::WebDriver::Error::StaleElementReferenceError
  retries += 1
  retry if retries < 3
  raise
end
```

**Issue: JavaScript chưa load xong**
```ruby
# Đợi AJAX hoàn thành
def wait_for_ajax
  Timeout.timeout(Capybara.default_max_wait_time) do
    loop until finished_all_ajax_requests?
  end
end

def finished_all_ajax_requests?
  page.evaluate_script('jQuery.active').zero?
end
```

---

## Chạy Tests

```bash
# Chạy tất cả system tests
bundle exec rspec spec/system

# Chạy 1 file
bundle exec rspec spec/system/authentication/sign_in_spec.rb

# Chạy 1 test cụ thể
bundle exec rspec spec/system/authentication/sign_in_spec.rb:10

# Chạy với format đẹp
bundle exec rspec spec/system --format documentation

# Chạy parallel (nhanh hơn)
gem install parallel_tests
bundle exec parallel_rspec spec/system
```

---

## Kết luận

Setup này cung cấp foundation vững chắc cho system testing. Một số điểm quan trọng:

1. **Start simple**: Bắt đầu với happy path trước, sau đó mới test edge cases
2. **Keep tests independent**: Mỗi test phải có thể chạy độc lập
3. **Use factories wisely**: Chỉ tạo data cần thiết cho từng test
4. **Test user flows, not implementation**: Focus vào những gì user làm, không phải code bên trong
5. **Maintain tests**: Khi feature thay đổi, update tests ngay

Bước tiếp theo:
- Setup CI/CD để chạy tests tự động
- Thêm test coverage cho các flows khác (booking, payment, etc.)
- Consider thêm visual regression testing với Percy/BackstopJS nếu cần

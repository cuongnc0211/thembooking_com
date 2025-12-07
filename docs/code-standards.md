# ThemBooking Code Standards & Best Practices

## Table of Contents
1. [General Principles](#general-principles)
2. [Code Organization](#code-organization)
3. [Naming Conventions](#naming-conventions)
4. [Controller Standards](#controller-standards)
5. [Model Standards](#model-standards)
6. [View Standards](#view-standards)
7. [Testing Standards](#testing-standards)
8. [Security Standards](#security-standards)
9. [Performance Guidelines](#performance-guidelines)
10. [Code Quality Tools](#code-quality-tools)

## General Principles

### 1. Ruby on Rails Conventions
- Follow standard Rails conventions unless explicitly documented otherwise
- Use Rails 8 defaults (Solid gems, authentication generator)
- Prefer Rails idioms over custom patterns

### 2. Test-Driven Development (TDD)
**ALL new features MUST follow this workflow:**

1. **SPEC FIRST** → Write RSpec tests defining expected behavior
2. **REVIEW** → Ask for approval before implementation
3. **IMPLEMENT** → Write minimal code to make tests pass
4. **VERIFY** → Run all tests, ensure green

### 3. Convention over Configuration
- Leverage Rails' conventions for naming, routing, and structure
- Keep configuration minimal and explicit
- Use Rails defaults where appropriate

### 4. Readability First
- Write code for humans, not computers
- Clear method names > clever code
- Explicit is better than implicit

## Code Organization

### Directory Structure
```
app/
├── controllers/
│   ├── application_controller.rb
│   ├── sessions_controller.rb
│   ├── dashboard/
│   │   ├── base_controller.rb
│   │   ├── onboarding_controller.rb
│   │   ├── businesses_controller.rb
│   │   └── profiles_controller.rb
├── models/
│   ├── user.rb
│   ├── business.rb
│   ├── service.rb
│   └── booking.rb
├── views/
│   ├── layouts/
│   │   ├── application.html.erb
│   │   └── dashboard.html.erb
│   ├── dashboard/
│   │   ├── onboarding/
│   │   │   └── _form.html.erb
│   │   └── businesses/
│   └── sessions/
├── javascript/
│   ├── controllers/
│   │   └── onboarding_controller.js
│   └── components/
│       └── calendar_picker.jsx
├── mailers/
│   └── user_mailer.rb
├── services/
│   └── bookings/
│       └── create_booking.rb
└── jobs/
    └── send_booking_confirmation_job.rb

spec/
├── models/
│   ├── user_spec.rb
│   ├── business_spec.rb
│   └── service_spec.rb
├── requests/
│   ├── sessions_spec.rb
│   └── dashboard/
│       ├── onboarding_spec.rb
│       └── businesses_spec.rb
├── services/
│   └── bookings/
│       └── create_booking_spec.rb
└── support/
    └── factories.rb

lib/
└── tasks/
```

### File Naming Conventions
- **Controllers**: Snake_case with `_controller.rb` suffix
  - `app/controllers/dashboard/onboarding_controller.rb`
- **Models**: Singular, CamelCase
  - `app/models/user.rb`
- **Views**: Snake_case, matching controller action
  - `app/views/dashboard/onboarding/show.html.erb`
- **Services**: Namespaced, snake_case
  - `app/services/bookings/create_booking.rb`
- **Jobs**: Descriptive, ends with `_job.rb`
  - `app/jobs/send_booking_confirmation_job.rb`
- **Tests**: Mirror file structure, end with `_spec.rb`

## Naming Conventions

### Ruby Naming
- **Classes**: CamelCase (e.g., `BookingService`)
- **Modules**: CamelCase (e.g., `Dashboard`)
- **Methods**: snake_case (e.g., `create_booking`)
- **Variables**: snake_case (e.g., `current_user`)
- **Constants**: SCREAMING_SNAKE_CASE (e.g., `ONBOARDING_STEPS`)
- **Boolean Methods**: Question prefix (e.g., `onboarding_completed?`)

### Database Naming
- **Tables**: Plural, snake_case (e.g., `users`)
- **Columns**: snake_case (e.g., `onboarding_step`)
- **Foreign Keys**: `<table>_id` (e.g., `user_id`)
- **Primary Keys**: `id` (Rails default)
- **Indexes**: Follow Rails conventions

### Frontend Naming
- **Classes**: kebab-case (e.g., `onboarding-step-1`)
- **IDs**: kebab-case (e.g., `main-form`)
- **JavaScript**: camelCase (e.g., `handleStepChange`)
- **React Components**: PascalCase (e.g., `OnboardingForm`)

### Variable Scope
```ruby
# Instance variables
@user
@business

# Local variables
current_user
onboarding_step

# Global variables (AVOID!)
$redis_cache

# Class variables (AVOID!)
@@shared_data

# Constants
ONBOARDING_STEPS
MAX_BOOKINGS_PER_DAY
```

## Controller Standards

### Controller Namespace Convention

**Public Controllers** (no authentication required):
```ruby
class SessionsController < ApplicationController
  # Login/logout - accessible to everyone
end

class RegistrationsController < ApplicationController
  # User signup - accessible to everyone
end

class PasswordsController < ApplicationController
  # Password reset - accessible to everyone
end
```

**Dashboard Namespace** (`app/controllers/dashboard/`):
```ruby
module Dashboard
  class BaseController < ApplicationController
    # Authentication required by default
    before_action :require_authentication
    before_action :require_onboarding_complete

    layout "dashboard"
  end

  class OnboardingController < BaseController
    # Handles its own access control via before_action
    before_action :redirect_if_completed
    before_action :validate_step_access
  end

  class BusinessesController < BaseController
    # Inherits authentication + onboarding checks
    before_action :set_business, only: [:show, :edit, :update]
  end
end
```

### Controller Best Practices

#### 1. Thin Controllers
Controllers should only handle:
- Authentication and authorization
- Request/response handling
- Simple data transformation
- Delegating to services/models

**Good:**
```ruby
def create
  @booking = BookingService.new(current_user, business_params).call
  redirect_to booking_path(@booking), notice: "Booking created"
end
```

**Bad:**
```ruby
def create
  @booking = Booking.new(business_params)
  if @booking.save
    # Send email
    UserMailer.booking_confirmation(@booking).deliver_later
    # Update analytics
    Analytics.track_booking_created(@booking)
    # Update cache
    Rails.cache.delete("business_#{params[:business_id]}_availability")
    redirect_to booking_path(@booking), notice: "Booking created"
  else
    render :new, status: :unprocessable_entity
  end
end
```

#### 2. Before Actions
```ruby
class Dashboard::BusinessesController < BaseController
  # Load specific business record
  before_action :set_business, only: [:show, :edit, :update]

  # Authorize business ownership
  before_action :authorize_business!, only: [:edit, :update]

  # Validate business exists
  before_action :validate_business!, only: [:show]
end
```

#### 3. Instance Variable Pattern
```ruby
def show
  @business = current_user.business
  @services = @business.services.active.order(:position)
  @stats = BusinessStatsService.new(@business).call
end
```

#### 4. Strong Parameters
```ruby
def business_params
  permitted = params.require(:business).permit(
    :name,
    :slug,
    :business_type,
    :description,
    :address,
    :phone,
    :capacity,
    operating_hours: {
      monday: [:open, :close, :closed, breaks: [:start, :end]],
      tuesday: [:open, :close, :closed, breaks: [:start, :end]]
    }
  )

  # Transform data
  permitted[:operating_hours] = normalize_hours(permitted[:operating_hours])
  permitted
end
```

#### 5. Error Handling
```ruby
def update
  @business = current_user.business

  if @business.update(business_params)
    redirect_to dashboard_business_path, notice: "Business updated"
  else
    render :edit, status: :unprocessable_entity
  end
end
```

## Model Standards

### 1. Validations
```ruby
class User < ApplicationRecord
  # Email validations
  validates :email_address, presence: true, uniqueness: { case_sensitive: false }
  validates :email_address, format: { with: URI::MailTo::EMAIL_REGEXP }

  # Password validations
  validates :password, length: { minimum: 8 }, if: -> { password.present? }

  # Custom validations
  validate :business_belongs_to_user, if: -> { business_id.present? }

  # Conditional validations
  validates :phone, presence: true, if: -> { onboarding_step >= 2 }
end
```

### 2. Associations
```ruby
class User < ApplicationRecord
  # Singular for one-to-one
  has_one :business, dependent: :destroy

  # Plural for one-to-many
  has_many :bookings, dependent: :restrict_with_error

  # Through associations
  has_many :services, through: :business

  # Counter caches
  has_many :businesses, counter_cache: true
end
```

### 3. Callbacks
```ruby
class User < ApplicationRecord
  before_validation :normalize_email
  before_create :generate_confirmation_token
  after_create :send_welcome_email

  private

  def normalize_email
    self.email_address = email_address.strip.downcase if email_address.present?
  end

  def generate_confirmation_token
    self.email_confirmation_token = SecureRandom.urlsafe_base64(32)
  end
end
```

### 4. Business Logic
```ruby
class User < ApplicationRecord
  # Constants
  ONBOARDING_STEPS = {
    user_info: 1,
    business: 2,
    hours: 3,
    services: 4,
    completed: 5
  }.freeze

  # Query methods
  scope :confirmed, -> { where.not(email_confirmed_at: nil) }
  scope :active, -> { where(deleted_at: nil) }

  # Business logic methods
  def onboarding_completed?
    onboarding_completed_at.present?
  end

  def can_access_step?(step_number)
    step_number <= onboarding_step
  end

  def advance_onboarding!
    return if onboarding_step >= 5

    new_step = onboarding_step + 1
    attrs = { onboarding_step: new_step }
    attrs[:onboarding_completed_at] = Time.current if new_step == 5
    update!(attrs)
  end
end
```

### 5. Enums
```ruby
class Booking < ApplicationRecord
  enum status: {
    pending: "pending",
    confirmed: "confirmed",
    in_progress: "in_progress",
    completed: "completed",
    cancelled: "cancelled",
    no_show: "no_show"
  }

  enum source: {
    online: "online",
    walk_in: "walk_in"
  }
end
```

## View Standards

### 1. Layout Usage
```erb
<!-- app/views/layouts/application.html.erb -->
<!DOCTYPE html>
<html>
  <head>
    <title>ThemBooking</title>
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>
    <%= stylesheet_link_tag "application" %>
  </head>
  <body>
    <%= yield %>
  </body>
</html>

<!-- app/views/layouts/dashboard.html.erb -->
<%= render "layouts/dashboard_header" %>
<main class="dashboard-container">
  <%= yield %>
</main>
<%= render "layouts/dashboard_footer" %>
```

### 2. View Structure
```erb
<!-- app/views/dashboard/onboarding/show.html.erb -->
<%# Set page title %>
<% content_for :page_title do %>
  <%= @step_config[:title] %>
<% end %>

<%# Form for step %>
<div class="onboarding-step">
  <h1><%= @step_config[:title] %></h1>

  <%= form_with(
    url: dashboard_onboarding_path,
    method: :patch,
    local: true,
    data: {
      turbo: true,
      controller: "onboarding",
      "onboarding-step-value": @step
    }
  ) do |form| %>
    <%# Step-specific form content %>
    <%= render "form_content", form: form %>

    <%= form.submit "Continue" %>
  <% end %>
</div>
```

### 3. Form Helpers
```erb
<%# Good: Using form_with %>
<%= form_with model: @business, url: dashboard_business_path, local: true do |form| %>
  <div class="form-group">
    <%= form.label :name %>
    <%= form.text_field :name, class: "form-control" %>
    <% if @business.errors[:name].any? %>
      <div class="error-message"><%= @business.errors[:name].to_sentence %></div>
    <% end %>
  </div>
<% end %>

<%# For simple forms without models %>
<%= form_with url: dashboard_onboarding_path, method: :patch, local: true do |form| %>
  <%= form.hidden_field :step, value: @step %>
  <%= form.fields_for :user, @user do |user_form| %>
    <%= user_form.label :name, "Full Name" %>
    <%= user_form.text_field :name %>
  <% end %>
<% end %>
```

### 4. Conditional Content
```erb
<%# Good: Using helper methods %>
<% if @user.onboarding_completed? %>
  <%= link_to "View Dashboard", dashboard_path %>
<% else %>
  <%= link_to "Complete Setup", dashboard_onboarding_path %>
<% end %>

<%# Bad: Logic in views %>
<% if @user.onboarding_step == 5 && @user.onboarding_completed_at.present? %>
  <%# complex logic %>
<% end %>
```

### 5. Partials for Reusable Components
```erb
<!-- app/views/dashboard/shared/_nav.html.erb -->
<nav class="dashboard-nav">
  <%= link_to "Business", dashboard_business_path %>
  <%= link_to "Services", dashboard_services_path %>
  <%= link_to "Bookings", dashboard_bookings_path %>
</nav>
```

## Testing Standards

### 1. Testing Structure
```ruby
# spec/models/user_spec.rb
require "rails_helper"

RSpec.describe User, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:business).optional }
    it { is_expected.to have_many(:bookings) }
  end

  describe "validations" do
    subject { build(:user) }

    it { is_expected.to validate_presence_of(:email_address) }
    it { is_expected.to validate_uniqueness_of(:email_address).case_insensitive }
  end

  describe "onboarding" do
    let(:user) { create(:user) }

    describe "#onboarding_completed?" do
      it "returns false when onboarding not completed" do
        user.update(onboarding_step: 3)
        expect(user.onboarding_completed?).to be false
      end

      it "returns true when onboarding completed" do
        user.update(onboarding_step: 5, onboarding_completed_at: Time.current)
        expect(user.onboarding_completed?).to be true
      end
    end
  end
end
```

### 2. Request/Controller Tests
```ruby
# spec/requests/dashboard/onboarding_spec.rb
require "rails_helper"

RSpec.describe "Dashboard::Onboarding", type: :request do
  def sign_in(user)
    post session_path, params: { email_address: user.email_address, password: "password123" }
  end

  describe "GET /dashboard/onboarding" do
    context "when onboarding not completed" do
      let(:user) { create(:user, onboarding_step: 1) }

      before { sign_in(user) }

      it "renders the current step form" do
        get dashboard_onboarding_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Step 1")
      end

      it "advances to next step on successful update" do
        patch dashboard_onboarding_path, params: { user: { name: "John", phone: "0901234567" } }
        expect(user.reload.onboarding_step).to eq(2)
      end
    end
  end
end
```

### 3. Service Object Tests
```ruby
# spec/services/bookings/create_booking_spec.rb
require "rails_helper"

RSpec.describe Bookings::CreateBooking, type: :service do
  let(:business) { create(:business) }
  let(:service) { create(:service, business: business) }
  let(:user) { business.user }

  describe "#call" do
    context "with valid parameters" do
      let(:params) do
        {
          service_id: service.id,
          date: Date.tomorrow,
          time: "10:00",
          customer_name: "John Doe",
          customer_phone: "0901234567"
        }
      end

      it "creates a booking" do
        expect {
          described_class.new(business: business, params: params).call
        }.to change(Booking, :count).by(1)
      end

      it "returns success result" do
        result = described_class.new(business: business, params: params).call
        expect(result.success?).to be true
        expect(result.booking).to be_persisted
      end
    end

    context "with invalid parameters" do
      let(:params) { { service_id: nil } }

      it "returns error result" do
        result = described_class.new(business: business, params: params).call
        expect(result.success?).to be false
        expect(result.errors).to be_present
      end
    end
  end
end
```

### 4. Factory Definitions
```ruby
# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    sequence(:email_address) { |n| "user#{n}@example.com" }
    password { "password123" }
    name { "John Doe" }
    sequence(:phone) { |n| "0901234#{n.to_s.rjust(3, '0')}" }
    email_confirmed_at { Time.current }

    trait :onboarding_completed do
      onboarding_step { 5 }
      onboarding_completed_at { Time.current }
    end

    trait :with_business do
      after(:create) do |user|
        create(:business, user: user)
      end
    end
  end
end

# spec/factories/businesses.rb
FactoryBot.define do
  factory :business do
    name { "John's Barbershop" }
    slug { "johns-barbershop" }
    business_type { "barber" }
    description { "Professional barber services" }
    address { "123 Main St, District 1, Ho Chi Minh City" }
    phone { "0901234567" }
    capacity { 3 }
    operating_hours {
      {
        "monday" => { "open" => "09:00", "close" => "19:00", "closed" => false },
        "tuesday" => { "open" => "09:00", "close" => "19:00", "closed" => false },
        # ... other days
      }
    }

    association :user
  end
end
```

## Security Standards

### 1. Authentication & Authorization
```ruby
class ApplicationController < ActionController::Base
  before_action :require_authentication

  private

  def require_authentication
    return if current_user

    redirect_to new_session_path, alert: "Please sign in to continue."
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end
end
```

### 2. Strong Parameters
```ruby
def business_params
  params.require(:business).permit(
    :name,
    :slug,
    :business_type,
    :description,
    :address,
    :phone,
    :capacity,
    operating_hours: {}
  )
end
```

### 3. SQL Injection Prevention
```ruby
# GOOD: Using Rails methods
User.where(email: params[:email])
Business.find_by(id: params[:id])

# AVOID: Raw SQL
User.where("email = '#{params[:email]}'")
```

### 4. XSS Prevention
```erb
<%# Rails automatically escapes output %>
<%= @user.name %>  <!-- Safe -->

<%# Raw output only when sanitized %>
<%= sanitize(@user.bio) %>

<%# JavaScript content in data attributes %>
<div data-controller="calendar" data-calendar-dates="<%= @dates.to_json %>"></div>
```

### 5. CSRF Protection
```erb
<!-- All forms should include CSRF token -->
<%= form_with url: some_path do |form| %>
  <!-- Automatically includes CSRF token -->
<% end %>
```

## Performance Guidelines

### 1. N+1 Query Prevention
```ruby
# BAD: N+1 queries
<% @businesses.each do |business| %>
  <%= business.services.count %>
<% end %>

# GOOD: Counter cache
<% @businesses.each do |business| %>
  <%= business.services_count %>
<% end %>
```

### 2. Efficient Database Queries
```ruby
# GOOD: Using includes
@bookings = Booking.includes(:service, :business).where(business_id: @business.id)

# GOOD: Using scopes
Business.active.where("created_at > ?", 1.week.ago)
```

### 3. Caching Strategy
```ruby
class Business < ApplicationRecord
  # Low-level caching for frequently accessed data
  def cached_stats
    Rails.cache.fetch("business_#{id}_stats", expires_in: 1.hour) do
      calculate_stats
    end
  end
end
```

### 4. Background Jobs
```ruby
class BookingMailer < ApplicationMailer
  def confirmation(booking)
    @booking = booking
    mail(to: @booking.customer_email, subject: "Booking Confirmation")
  end
end

# In controller
def create
  @booking = Booking.create!(booking_params)
  BookingMailer.confirmation(@booking).deliver_later  # Background job
end
```

## Code Quality Tools

### 1. RuboCop Configuration
```yaml
# .rubocop.yml
AllCops:
  NewCops: enable
  TargetRubyVersion: 3.3

# Layout cops
Layout/ClassLength:
  Max: 200

Layout/MethodLength:
  Max: 15

# Style cops
Style/FrozenStringLiteralComment:
  Enabled: true

Style/Documentation:
  Enabled: false

# Rails cops
Rails/Delegate:
  Enabled: true

Rails/FindBy:
  Enabled: true
```

### 2. Testing Tools
```bash
# Run all tests
bundle exec rspec

# Run with coverage
COVERAGE=true bundle exec rspec

# Run specific test file
bundle exec rspec spec/models/user_spec.rb

# Run with documentation format
bundle exec rspec --format documentation
```

### 3. Code Review Checklist
- [ ] Tests follow TDD process
- [ ] Code follows naming conventions
- [ ] Controllers are thin and delegate properly
- [ ] Models have proper validations and associations
- [ ] Security considerations implemented
- [ ] Performance issues addressed (N+1 queries, etc.)
- [ ] Documentation updated for new features
- [ ] All tests pass
- [ ] RuboCop passes without offenses

## Conclusion

These code standards ensure consistency, maintainability, and quality across the ThemBooking codebase. Adherence to these guidelines is mandatory for all contributors and will be enforced through code reviews and automated tools.

*Last Updated*: December 7, 2025
*Version*: v0.1.2
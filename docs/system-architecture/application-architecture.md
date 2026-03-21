# Application Architecture

## Layered Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                      │
│  ┌─────────────────────────────────────────────────────┐  │
│  │         View Layer (ERB/React)                      │  │
│  │  Dashboard Views | Public Views | Booking Views    │  │
│  └─────────────────────────────────────────────────────┘  │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐  │
│  │         Controller Layer                            │  │
│  │  Application | Dashboard | Sessions | Admin         │  │
│  └─────────────────────────────────────────────────────┘  │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐  │
│  │      Business Logic Layer                           │  │
│  │  Service Objects | Models | Domain Entities        │  │
│  └─────────────────────────────────────────────────────┘  │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐  │
│  │      Data Access Layer                              │  │
│  │  Active Record | PostgreSQL | Redis Cache           │  │
│  └─────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Controller Patterns

### Public Controllers (No Authentication Required)

```ruby
class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]

  def new
    # Login form
  end

  def create
    if user = User.authenticate_by(email_address: params[:email], password: params[:password])
      start_new_session_for user
      redirect_to dashboard_path
    else
      redirect_to new_session_path, alert: "Invalid credentials"
    end
  end
end
```

### Dashboard Controllers (Authentication Required)

```ruby
module Dashboard
  class BaseController < ApplicationController
    layout "dashboard"
    before_action :require_onboarding_complete

    private

    def require_onboarding_complete
      redirect_to dashboard_onboarding_path unless current_user.onboarding_completed?
    end
  end

  class OnboardingController < BaseController
    before_action :redirect_if_completed

    def redirect_if_completed
      redirect_to dashboard_root_path if current_user.onboarding_completed?
    end
  end
end
```

## Service Objects Pattern

### Booking Availability Check (Branch-Scoped)

```ruby
module Bookings
  class CheckAvailability
    SLOT_INTERVAL = 15.minutes
    ACTIVE_STATUSES = %w[pending confirmed in_progress].freeze

    def initialize(branch:, service: nil, service_ids: nil, date:)
      @branch = branch
      @service_ids = service_ids ? Array(service_ids) : nil
      @date = date.is_a?(String) ? Date.parse(date) : date
    end

    def call
      return [] if branch_closed_on_date?

      day_hours = operating_hours_for_date
      return [] if day_hours.nil? || day_hours["closed"]

      total_duration = calculate_total_duration
      return [] if total_duration.zero?

      candidates = generate_candidate_times(day_hours, total_duration)
      candidates.select { |start_time| available_at?(start_time, total_duration) }
    end

    private

    def branch_closed_on_date?
      @branch.business_closures.exists?(date: @date)
    end

    def available_at?(start_time, duration_minutes)
      end_time = start_time + duration_minutes.minutes
      overlap_count = @branch.bookings
        .where(status: ACTIVE_STATUSES)
        .where("scheduled_at < ? AND end_time > ?", end_time, start_time)
        .count
      overlap_count < @branch.capacity
    end
  end
end
```

**Phase 1 Changes**: Service now accepts `branch:` parameter. Queries respect branch-level capacity, operating hours, and business closures. All availability checks are now branch-scoped.

### Usage in Controllers

```ruby
def check_availability
  result = Bookings::CheckAvailability.new(
    branch: @branch,
    service_ids: params[:service_ids],
    date: params[:date]
  ).call

  render json: result
end
```

## Domain Models

### Business (Brand Entity)

```ruby
class Business < ApplicationRecord
  belongs_to :user
  has_many :branches, dependent: :destroy
  has_many :services, through: :branches
  has_many :bookings, through: :branches
  has_one_attached :logo

  BUSINESS_TYPES = %w[barber salon spa nail other]
  enum :business_type, BUSINESS_TYPES.zip(BUSINESS_TYPES).to_h

  validates :name, presence: true, length: { maximum: 100 }
  validates :business_type, presence: true
  validates :user_id, uniqueness: { message: "already has a business" }
end
```

### Branch (Physical Location)

```ruby
class Branch < ApplicationRecord
  belongs_to :business
  has_many :services, dependent: :destroy
  has_many :bookings, dependent: :destroy
  has_many :business_closures, dependent: :destroy

  WEEKDAYS = %w[monday tuesday wednesday thursday friday saturday sunday].freeze

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: { case_sensitive: false },
            format: { with: /\A[a-z0-9\-]+\z/ }
  validates :capacity, numericality: { only_integer: true, greater_than: 0 }
  validate :operating_hours_format
  validate :operating_hours_logic
  validate :breaks_within_operating_hours

  def operating_on?(datetime)
    return false unless datetime
    day_name = datetime.strftime("%A").downcase
    hours = hours_for(day_name)
    return false unless hours && !hours["closed"]
    time_str = datetime.strftime("%H:%M")
    time_str >= hours["open"] && time_str < hours["close"] && !on_break?(datetime)
  end

  def open_on?(day_name)
    hours = operating_hours&.dig(day_name.to_s.downcase)
    return false unless hours
    !hours["closed"]
  end

  def current_capacity_usage
    bookings.where(status: :in_progress).count
  end

  def capacity_percentage
    return 0 if capacity.zero?
    (current_capacity_usage.to_f / capacity * 100).round
  end

  def booking_url
    if Rails.env.development?
      "localhost:3000/#{slug}"
    else
      "thembooking.com/#{slug}"
    end
  end
end
```

### Service Model

```ruby
class Service < ApplicationRecord
  belongs_to :branch
  has_many :booking_services, dependent: :destroy
  has_many :bookings, through: :booking_services

  validates :name, presence: true
  validates :duration_minutes, numericality: { only_integer: true, greater_than: 0 }
  validates :price_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :branch_id, presence: true
end
```

### Booking Model

```ruby
class Booking < ApplicationRecord
  belongs_to :branch
  has_many :booking_services, dependent: :destroy
  has_many :services, through: :booking_services

  validates :end_time, presence: true
  validates :customer_name, presence: true
  validates :scheduled_at, presence: true

  enum :status, {
    pending: 0,
    confirmed: 1,
    in_progress: 2,
    completed: 3,
    cancelled: 4,
    no_show: 5
  }

  enum :source, {
    online: 0,
    walk_in: 1
  }

  after_create_commit :broadcast_booking_created
  after_update_commit :broadcast_booking_updated
  after_destroy_commit :broadcast_booking_destroyed
end
```

### User Model

```ruby
class User < ApplicationRecord
  has_secure_password
  has_one :business, dependent: :destroy
  has_many :sessions, dependent: :destroy

  validates :email_address, presence: true, uniqueness: { case_sensitive: false }
  validates :email_address, format: { with: URI::MailTo::EMAIL_REGEXP }

  def onboarding_completed?
    onboarding_completed_at.present?
  end

  def advance_onboarding!
    return if onboarding_step >= 5
    new_step = onboarding_step + 1
    attrs = { onboarding_step: new_step }
    attrs[:onboarding_completed_at] = Time.current if new_step == 5
    update!(attrs)
  end

  def can_access_step?(step_number)
    step_number <= onboarding_step
  end
end
```

## Request/Response Patterns

### Booking Creation with Overlap Handling

1. Client submits booking form with `scheduled_at`, `duration`, `customer_info`
2. Controller loads branch and validates params
3. Service calculates `end_time` from `scheduled_at` + service duration
4. Database advisory lock prevents concurrent overbooking
5. Booking record created, broadcasts to real-time subscribers
6. Email confirmation sent in background job

### Availability Query Flow

1. Client requests available slots for date + services
2. Controller loads branch and service(s)
3. `CheckAvailability` service queries:
   - BusinessClosure for that date
   - operating_hours JSONB for day-of-week
   - Overlapping bookings from database
4. Returns array of available time windows (15-min intervals)
5. Client renders in UI, user selects slot

*Last Updated*: March 14, 2026
*Version*: v0.2.1 (Phase 3 Public Booking + Phase 4 Tests Complete)

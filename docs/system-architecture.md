# ThemBooking System Architecture Documentation

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Technical Stack](#technical-stack)
3. [Data Architecture](#data-architecture)
4. [Application Architecture](#application-architecture)
5. [Security Architecture](#security-architecture)
6. [Performance Architecture](#performance-architecture)
7. [Deployment Architecture](#deployment-architecture)
8. [Scalability Considerations](#scalability-considerations)
9. [Monitoring & Observability](#monitoring--observability)

## Architecture Overview

### System Context Diagram
```
┌─────────────────────────────────────────────────────────────────────┐
│                           ThemBooking                              │
│                                                                     │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐         │
│  │   Users     │    │  Businesses │    │ Customers   │         │
│  │  (Owners)   │    │   (Service  │    │   (Clients) │         │
│  └─────────────┘    │   Providers) │    └─────────────┘         │
│                     └─────────────┘                             │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                     Application Layer                        │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐       │  │
│  │  │  Dashboard │  │  Public     │  │  Booking   │       │  │
│  │  │  Interface │  │  Interface  │  │  System    │       │  │
│  │  └─────────────┘  └─────────────┘  └─────────────┘       │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                     Business Logic Layer                      │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐       │  │
│  │  │  Services   │  │   Models    │  │   Domain    │       │  │
│  │  │  Objects    │  │   Logic     │  │  Entities   │       │  │
│  │  └─────────────┘  └─────────────┘  └─────────────┘       │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                     Data Access Layer                        │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐       │  │
│  │  │  PostgreSQL│  │   Redis     │  │   Active   │       │  │
│  │  │   Database  │  │   Cache     │  │    Storage │       │  │
│  │  └─────────────┘  └─────────────┘  └─────────────┘       │  │
│  └─────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘

                           External Dependencies
                    ┌─────────────┐  ┌─────────────┐  ┌─────────────┐
                    │   Email     │  │   Payment    │  │  Analytics  │
                    │  Service    │  │  Gateway     │  │   Service   │
                    │ (SendGrid)  │  │   (Sepay)    │  │   (Mixpanel)│
                    └─────────────┘  └─────────────┘  └─────────────┘
```

### Architectural Principles
1. **Modularity**: Clean separation of concerns with bounded contexts
2. **Simplicity**: Rails conventions and minimal abstractions
3. **Security**: Defense in depth with multiple security layers
4. **Performance**: Database optimization and caching strategies
5. **Scalability**: Stateless services and horizontal scaling capability
6. **Maintainability**: Comprehensive testing and documentation

## Technical Stack

### Backend Technology Stack
```yaml
Ruby: 3.3.0 (asdf managed)
Rails: 8.0.0 (with modern defaults)
├── Solid Queue: Background job processing
├── Solid Cable: WebSocket connections
├── Solid Cache: Redis caching
└── Rails Authentication: Secure password handling

Database: PostgreSQL 14+
├── Primary data storage
├── ACID compliance
├── JSONB support
└── Full-text search capability

Caching: Redis 6+
├── Session storage
├── Query result caching
├── Rate limiting
└── Real-time presence

Background Jobs: Solid Queue
├── Built-in job processing
├── Retry mechanisms
├── Monitoring (via Mission Control)
└── No additional infrastructure needed
```

### Frontend Technology Stack
```yaml
Rendering: Rails Server-Side Rendering
├── Hotwire (Turbo + Stimulus)
├── React components (selective use)
├── Tailwind CSS
└── Progressive Web App support

Client-Side:
├── Turbo: AJAX and navigation
├── Stimulus: JavaScript controllers
├── React: Complex components
└── Webpacker: Asset compilation

Styling:
├── Tailwind CSS: Utility-first
├── Custom CSS: Minimal override
├── Responsive design
└── Dark mode support
```

### Infrastructure Stack
```yaml
Deployment: Kamal
├── Docker containerization
├── Zero-downtime deployments
├── Automated rollbacks
└── SSL/TLS management

Hosting: Self-hosted on PC infrastructure
├── Custom PC as server
├── Cloudflare Tunnel for secure access
├── Local PostgreSQL instance
└── Redis running locally

Monitoring:
├── Application logs (Kamal)
├── Database monitoring
├── Error tracking (Sentry - future)
└── Performance monitoring (New Relic - future)
```

## Data Architecture

### Database Schema Overview
```mermaid
erDiagram
    USER ||--o{ BUSINESS : "1 to many"
    USER ||--o{ SESSION : "1 to many"
    USER ||--o{ BUSINESS : "has one"

    BUSINESS ||--o{ SERVICE : "1 to many"
    BUSINESS ||--o{ BOOKING : "1 to many"
    BUSINESS ||--o{ STAFF : "1 to many"
    BUSINESS ||--o{ RESOURCE : "1 to many"

    SERVICE ||--o{ BOOKING : "1 to many"

    USER {
        bigint id PK
        string email_address UK
        string password_digest
        string name
        string phone
        string time_zone
        datetime email_confirmed_at
        datetime email_confirmation_token
        datetime email_confirmation_sent_at
        integer onboarding_step
        datetime onboarding_completed_at
        datetime created_at
        datetime updated_at
    }

    BUSINESS {
        bigint id PK
        bigint user_id FK
        string name
        string slug
        string business_type
        text description
        string address
        string phone
        integer capacity
        jsonb operating_hours
        string logo
        datetime created_at
        datetime updated_at
    }

    SERVICE {
        bigint id PK
        bigint business_id FK
        string name
        integer duration_minutes
        integer price_cents
        string currency
        text description
        boolean active
        integer position
        datetime created_at
        datetime updated_at
    }

    BOOKING {
        bigint id PK
        bigint business_id FK
        bigint service_id FK
        string customer_name
        string customer_phone
        string customer_email
        date booking_date
        time booking_time
        enum status
        enum source
        string notes
        datetime started_at
        datetime completed_at
        datetime created_at
        datetime updated_at
    }

    SESSION {
        bigint id PK
        bigint user_id FK
        string token
        datetime expires_at
        datetime created_at
    }
```

### Data Relationships and Cardinality
1. **User → Business**: One-to-One (one business per user initially)
2. **Business → Services**: One-to-Many (multiple services per business)
3. **Business → Bookings**: One-to-Many (multiple bookings per business)
4. **Service → Bookings**: One-to-Many (multiple bookings per service)
5. **Business → Staff**: One-to-Many (optional, future feature)
6. **Business → Resources**: One-to-Many (optional, future feature)

### Database Optimization Strategies
```sql
-- Indexes for performance
CREATE INDEX idx_users_email ON users(email_address);
CREATE INDEX idx_businesses_user_id ON businesses(user_id);
CREATE INDEX idx_bookings_business_id ON bookings(business_id);
CREATE INDEX idx_bookings_date_time ON bookings(booking_date, booking_time);
CREATE INDEX idx_services_business_id ON services(business_id);

-- Partial indexes for filtering
CREATE INDEX idx_bookings_pending ON bookings(status) WHERE status = 'pending';
CREATE INDEX idx_services_active ON services(active) WHERE active = true;

-- JSONB indexes for operating hours
CREATE INDEX idx_businesses_operating_hours ON businesses USING GIN(operating_hours);
```

### Data Migration Strategy
```ruby
# Version-controlled migrations
class CreateUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :users do |t|
      # User fields with type safety
      t.string :email_address, null: false, index: { unique: true }
      t.string :password_digest, null: false
      t.string :name
      t.string :phone
      t.string :time_zone, default: "Asia/Ho_Chi_Minh"
      t.datetime :email_confirmed_at
      t.string :email_confirmation_token
      t.datetime :email_confirmation_sent_at
      t.integer :onboarding_step, default: 1, null: false
      t.datetime :onboarding_completed_at

      t.timestamps null: false
    end
  end
end

# Seed data for development
class SeedInitialData < ActiveRecord::Migration[7.0]
  def change
    # Add business types enum
    add_column :businesses, :business_type, :string, default: "barber"

    # Add capacity column
    add_column :businesses, :capacity, :integer, default: 1, null: false

    # Add operating_hours as JSONB
    add_column :businesses, :operating_hours, :jsonb, default: {}
  end
end
```

## Application Architecture

### Layered Architecture
```
┌─────────────────────────────────────────────────────────────────────┐
│                         Presentation Layer                        │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                View Layer (ERB/React)                       │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐       │  │
│  │  │  Dashboard │  │   Public    │  │   Booking   │       │  │
│  │  │   Views    │  │    Views    │  │    Views    │       │  │
│  │  └─────────────┘  └─────────────┘  └─────────────┘       │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                     Controller Layer                         │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐       │  │
│  │  │Application │  │ Dashboard  │  │  Sessions  │       │  │
│  │  │Controller  │  │ Controller │  │ Controller │       │  │
│  │  └─────────────┘  └─────────────┘  └─────────────┘       │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                   Business Logic Layer                        │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐       │  │
│  │  │  Services   │  │   Models    │  │   Domain    │       │  │
│  │  │  Objects    │  │  & Methods  │  │  Entities   │       │  │
│  │  └─────────────┘  └─────────────┘  └─────────────┘       │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                     Data Access Layer                        │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐       │  │
│  │  │Active Record│  │  PostgreSQL │  │   Redis     │       │  │
│  │  │ & Queries  │  │    Driver   │  │   Cache     │       │  │
│  │  └─────────────┘  └─────────────┘  └─────────────┘       │  │
│  └─────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

### Controller Architecture Patterns

#### Public Controllers (No Authentication Required)
```ruby
class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]

  def new
    # Login form - no authentication required
  end

  def create
    # Authentication logic
    if user = User.authenticate_by(email_address: params[:email], password: params[:password])
      start_new_session_for user
      redirect_to dashboard_path
    else
      redirect_to new_session_path, alert: "Invalid credentials"
    end
  end
end
```

#### Dashboard Controllers (Authentication Required)
```ruby
module Dashboard
  class BaseController < ApplicationController
    # Authentication required by default
    layout "dashboard"

    # Onboarding completion check
    before_action :require_onboarding_complete

    private

    def require_onboarding_complete
      redirect_to dashboard_onboarding_path unless current_user.onboarding_completed?
    end
  end

  class OnboardingController < BaseController
    # Special case - handles its own access control
    before_action :redirect_if_completed

    def redirect_if_completed
      redirect_to dashboard_root_path if current_user.onboarding_completed?
    end
  end
end
```

### Service Object Pattern
```ruby
# app/services/bookings/check_availability.rb
module Bookings
  class CheckAvailability
    def initialize(business:, date:, service:)
      @business = business
      @date = date
      @service = service
    end

    def call
      validate_inputs!
      check_operating_hours!
      check_existing_bookings!
      check_capacity!
      available_slots
    end

    private

    def validate_inputs!
      raise ArgumentError, "Invalid date" unless @date.is_a?(Date)
      raise ArgumentError, "Business required" unless @business.present?
      raise ArgumentError, "Service required" unless @service.present?
    end

    def check_operating_hours!
      # Implementation
    end

    def check_existing_bookings!
      # Implementation
    end

    def check_capacity!
      # Implementation
    end

    def available_slots
      # Return array of available time slots
    end
  end
end

# Usage in controller
def check_availability
  result = Bookings::CheckAvailability.new(
    business: @business,
    date: params[:date],
    service: @service
  ).call

  render json: result
end
```

### Domain Model Design
```ruby
class User < ApplicationRecord
  # Attributes
  attribute :email_confirmed_at, :datetime
  attribute :onboarding_step, :integer, default: 1
  attribute :onboarding_completed_at, :datetime

  # Constants
  ONBOARDING_STEPS = {
    user_info: 1,
    business: 2,
    hours: 3,
    services: 4,
    completed: 5
  }.freeze

  # Associations
  has_one :business, dependent: :destroy
  has_many :sessions, dependent: :destroy

  # Validations
  validates :email_address, presence: true, uniqueness: { case_sensitive: false }
  validates :email_address, format: { with: URI::MailTo::EMAIL_REGEXP }

  # Business Logic
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

## Security Architecture

### Multi-Layer Security Approach

#### 1. Network Security
```yaml
Infrastructure:
  Cloudflare Tunnel: End-to-end encryption
  Firewall: Block unnecessary ports
  SSL/TLS: HTTPS enforcement via Let's Encrypt

Application:
  CSP: Content Security Policy headers
  HSTS: HTTP Strict Transport Security
  X-Frame-Options: Clickjacking protection
  X-Content-Type-Options: MIME type sniffing protection
```

#### 2. Authentication Architecture
```ruby
# Multi-factor authentication ready
class User < ApplicationRecord
  # Password hashing with bcrypt
  has_secure_password

  # Session management
  has_many :sessions, dependent: :destroy

  # Email verification
  before_create :generate_confirmation_token

  def confirm!
    update!(email_confirmed_at: Time.current, email_confirmation_token: nil)
  end
end

# Session controller with security
class SessionsController < ApplicationController
  rate_limit to: 5, within: 1.minute, only: :create

  def create
    if user = User.authenticate_by(email_address: params[:email], password: params[:password])
      unless user.confirmed?
        redirect_to root_path, alert: "Please confirm your email"
        return
      end

      # Create secure session
      start_new_session_for user

      # Track login events
      SecurityLog.login_attempt(user, request)
    end
  end
end
```

#### 3. Authorization Patterns
```ruby
class ApplicationController < ActionController::Base
  private

  def require_authentication
    return if current_user

    redirect_to new_session_path, alert: "Please sign in"
  end

  def require_business!
    return if current_user.business

    redirect_to dashboard_onboarding_path, alert: "Please complete setup"
  end
end

# Resource-based authorization
class BookingPolicy < ApplicationPolicy
  def show?
    record.business.user == user
  end

  def create?
    user.business.present? && user.onboarding_completed?
  end
end
```

#### 4. Data Protection
```ruby
# Strong parameters for data sanitization
def booking_params
  params.require(:booking).permit(
    :service_id,
    :booking_date,
    :booking_time,
    :customer_name,
    :customer_phone,
    :customer_email,
    :notes
  )
end

# Sensitive data handling
class User < ApplicationRecord
  # Never store plain text passwords
  has_secure_password

  # Encrypt sensitive fields if needed
  attr_encrypted :phone, key: Rails.application.credentials.secret_key_base
end
```

### Security Headers Implementation
```ruby
# config/application.rb
config.action_dispatch.default_headers = {
  'X-Frame-Options' => 'SAMEORIGIN',
  'X-XSS-Protection' => '1; mode=block',
  'X-Content-Type-Options' => 'nosniff',
  'X-Download-Options' => 'noopen',
  'X-Permitted-Cross-Domain-Policies' => 'none',
  'Referrer-Policy' => 'strict-origin-when-cross-origin'
}
```

## Performance Architecture

### Caching Strategy

#### 1. Multi-Level Caching
```ruby
# Fragment caching for views
<% cache "business_#{business.id}_services", expires_in: 1.hour do %>
  <%= render partial: "services/service", collection: business.services, as: :service %>
<% end %>

# Russian doll caching
<% cache business do %>
  <% cache business.services do %>
    <%= render business.services %>
  <% end %>
<% end %>

# Low-level caching with Redis
class Business < ApplicationRecord
  def cached_services_count
    Rails.cache.fetch("business_#{id}_services_count", expires_in: 1.hour) do
      services.count
    end
  end
end
```

#### 2. Database Query Optimization
```ruby
# Eager loading associations
@businesses = Business.includes(:services, :bookings).where(user: current_user)

# Counter caches for performance
class Business < ApplicationRecord
  has_many :services, dependent: :destroy
  has_many :bookings, dependent: :restrict_with_error
end

class Service < ApplicationRecord
  belongs_to :business, counter_cache: true
end

# Batch processing for large datasets
class Bookings::ImportService
  def call(file_path)
    CSV.foreach(file_path, headers: true) do |row|
      Booking.create!(row.to_hash)
    end
  end
end
```

### Background Processing
```ruby
# Solid Queue for background jobs
class BookingMailer < ApplicationMailer
  def confirmation(booking)
    @booking = booking
    mail(to: @booking.customer_email, subject: "Booking Confirmation")
  end
end

# Usage in controllers
def create
  @booking = Booking.new(booking_params)

  if @booking.save
    # Send email in background
    BookingMailer.confirmation(@booking).deliver_later

    # Update analytics in background
    Analytics.track_booking_created(@booking)
  end
end
```

### Asset Optimization
```yaml
# config/environments/production.rb
config.assets.js_compressor = :terser
config.assets.css_compressor = :sass
config.assets.compile = false
config.assets.digest = true
config.cache_classes = true
config.eager_load = true
```

## Deployment Architecture

### Containerized Deployment with Docker
```dockerfile
# Dockerfile
FROM ruby:3.3.0-alpine AS base

# Install system dependencies
RUN apk add --no-cache \
    postgresql-dev \
    nodejs \
    npm \
    build-base \
    tzdata

# Install Rails and gems
WORKDIR /app
COPY Gemfile Gemfile.lock ./
RUN bundle config set --local without 'development test' && \
    bundle install --jobs 4

# Copy application code
COPY . .

# Precompile assets
RUN bundle exec rails assets:precompile

# Production stage
FROM base as production
ENV RAILS_ENV=production
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
```

### Kamal Deployment Configuration
```yaml
# config/kamal.yml
service: thembooking
servers:
  - "mypc.cuongnguyenfu.com"
registry:
  username: your-username
  password: your-password
  server: docker.io

# Environment variables
env:
  RAILS_ENV: production
  DATABASE_URL: postgres://user:pass@localhost/thembooking_production
  REDIS_URL: redis://localhost:6379/0
  SECRET_KEY_BASE: your-secret-key

# Hooks for deployment
hooks:
  build:
    - bundle install
    - rails assets:precompile
  deploy:
    - rails db:migrate
    - rails db:seed
```

### Infrastructure as Code
```bash
# Deployment script
#!/bin/bash
# deploy.sh

# Deploy to production
kamal deploy --trace

# Check deployment status
kamal app details

# View logs
kamal app logs -f

# Rollback if needed
kamal app rollback
```

## Scalability Considerations

### Database Scaling
```yaml
Current Architecture:
  Single PostgreSQL instance
  Read replica capability
  Connection pooling (pgbouncer)

Future Scaling:
  Read replicas for reporting
  Partitioning for large tables
  Connection pooling for high traffic
  Database sharding if needed
```

### Application Scaling
```yaml
Current State:
  Single application instance
  Stateless design for horizontal scaling

Scaling Strategy:
  Load balancing with nginx
  Multiple application instances
  Auto-scaling based on CPU/memory
  Session storage in Redis
```

### Caching Strategy Scaling
```yaml
Current Cache:
  Redis for sessions and fragments
  Database query caching

Future Enhancements:
  CDN for static assets
  Multi-level caching (CDN → Redis → Database)
  Cache warming for popular content
  Distributed caching across instances
```

### Queue Processing Scaling
```yaml
Current Queue:
  Solid Queue for background jobs
  Single worker process

Future Scaling:
  Multiple worker processes
  Queue prioritization
  Distributed job processing
  Dead letter queue for failed jobs
```

## Monitoring & Observability

### Application Monitoring
```ruby
# Request monitoring
class ApplicationController < ActionController::Base
  before_action :monitor_request

  private

  def monitor_request
    Rails.logger.info "Request started: #{request.method} #{request.path}"
    @request_start = Time.current
  end

  after_action do
    duration = Time.current - @request_start
    Rails.logger.info "Request completed in #{duration.round(3)}s"
  end
end
```

### Performance Monitoring
```yaml
Monitoring Stack:
  Application performance monitoring:
    - New Relic (planned)
    - Skylight (Rails-specific)

  Database monitoring:
    - PostgreSQL pg_stat_statements
    - Query performance insights

  Error tracking:
    - Sentry (planned)
    - Exception notifications
```

### Logging Architecture
```ruby
# Structured logging
Rails.logger.formatter = proc do |severity, timestamp, progname, msg|
  json = {
    timestamp: timestamp,
    severity: severity,
    progname: progname,
    message: msg,
    request_id: RequestStore.store[:request_id]
  }
  json.to_json + "\n"
end

# Request tracking
class ApplicationController < ActionController::Base
  around_action :set_request_id

  private

  def set_request_id
    RequestStore.store[:request_id] = SecureRandom.hex(8)
    yield
  ensure
    RequestStore.clear
  end
end
```

### Health Checks
```ruby
# Health check endpoint
class HealthController < ApplicationController
  def show
    # Database connectivity check
    ActiveRecord::Base.connection.execute('SELECT 1')

    # Redis connectivity check
    Redis.new.ping

    render json: {
      status: 'healthy',
      timestamp: Time.current,
      database: 'connected',
      cache: 'connected'
    }
  end
end
```

## Conclusion

The ThemBooking system architecture is designed for simplicity, maintainability, and scalability. Leveraging Rails 8 modern features and following established architectural patterns, the system provides a solid foundation for a booking platform serving the Vietnamese market.

Key architectural strengths:
- **Modern Rails 8 stack** with Solid gems reducing infrastructure dependencies
- **Clean separation of concerns** with layered architecture
- **Security-first approach** with multiple defense layers
- **Performance optimization** through caching and background processing
- **Containerized deployment** with Kamal for easy scaling
- **Comprehensive monitoring** capabilities for production operations

The architecture is ready to handle current requirements and provides clear pathways for future growth and feature expansion.

*Last Updated*: December 7, 2025
*Version*: v0.1.2
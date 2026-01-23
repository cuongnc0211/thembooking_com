# CLAUDE.md

This file provides guidance to AI agents (e.g. claude.ai/code) when working with code in this repository.

for the features definition and roadmap refer this file: .claude_plan/features.md


## Project Overview

**Project Name**: ThemBooking (thembooking.com)

**Description**: A booking and appointment management platform for service-based businesses. An affordable alternative to Fresha/Square Appointments, targeting local service businesses in Vietnam who need professional booking tools without premium pricing.

This product helps service businesses manage appointments, walk-ins, and daily operations through a simple booking system with a customizable landing page.

**Key Value Propositions**:
- Affordable pricing for Vietnamese market (99k-299k VND/month)
- Real-time queue and walk-in management (unique differentiator)
- Beautiful, customizable business landing page
- Simple capacity management (multiple clients served simultaneously)
- Vietnamese language and local payment support (Sepay)

**Target Users**:
- Barber shop owners
- Hair salon owners
- Spa and massage parlor owners
- Nail salon owners
- Beauty/aesthetic clinic owners
- Any service-based business needing appointment booking

**The pain points trying to solve:**
- **No-shows and scheduling chaos**: Customers don't show up, no way to track or reduce this
- **Walk-in vs appointment conflict**: Hard to balance walk-in customers with scheduled appointments
- **No online presence**: Many shops rely on Zalo/phone calls, no professional booking page
- **Manual tracking**: Using paper notebooks or memory to track appointments
- **Capacity blindness**: Don't know how many customers they can actually serve at once
- **No visibility for customers**: Customers can't see available times or current queue

---

## Tech Stack

### Backend
- **Rails 8**: Latest Rails with modern defaults
- **PostgreSQL**: Primary database
- **Redis**: Session storage and caching (via Solid Cache)
- **Solid Queue**: Background job processing (replacing Sidekiq/Resque)
- **Solid Cable**: WebSocket connections for real-time features

### Frontend
- **Rails SSR views**: Primary frontend
- **Hotwire (Turbo + Stimulus)**: Primary frontend interaction layer
- **React**: Used selectively for complex UI components (calendar picker, availability editor, etc.)
  - Integrated via `react-rails` gem or similar
  - Not a separate SPA - React components embedded in Rails views
- **Tailwind CSS**: Styling framework
- **Hotwire Native**: Mobile app wrapper for iOS/Android

### Deployment & Infrastructure
- **Kamal**: Deployment orchestrator
- **Docker**: Containerization
- **Server**: Set
- **Domain**: staging: thembooking.cuongnguyenfu.com / production: thembooking.com

### Development Tools
- **asdf**: Version manager for Ruby and Node.js
- Ruby version: [e.g., 3.3.0]
- Node version: [e.g., 20.x]

---

## Development Setup

### Prerequisites
```bash
# Install asdf if not already installed
# Install required plugins
asdf plugin add ruby
asdf plugin add nodejs

# Install versions specified in .tool-versions
asdf install

# Install system dependencies
# PostgreSQL 14+
# Redis 6+
```

### Initial Setup
```bash
# Clone the repository
git clone [your-repo-url]
cd thembooking

# Install dependencies
bundle install

# Setup database
rails db:create db:migrate db:seed

# Start development servers
bin/dev  # Runs Rails server + asset compilation
```

### Environment Variables
Create a `.env` file (or use Rails credentials):
```
DATABASE_URL=postgresql://localhost/[project]_development
REDIS_URL=redis://localhost:6379/0
SECRET_KEY_BASE=[generate with rails secret]

# Third-party services (to be added)
# GOOGLE_CALENDAR_CLIENT_ID=
# STRIPE_SECRET_KEY=
# SENDGRID_API_KEY=
```

### Common Commands
```bash
# Run tests
bundle exec rspec                    # Run all specs
bundle exec rspec spec/models/       # Run model specs only
bundle exec rspec --format documentation  # Verbose output

# Run console
rails console

# Asset compilation
rails assets:precompile

# Deploy
kamal deploy
```

---

## Project Structure

```
app/
├── controllers/
│   ├── dashboard/               # Authenticated dashboard namespace
│   │   ├── base_controller.rb   # Base controller (requires auth)
│   │   ├── profiles_controller.rb
│   │   └── businesses_controller.rb
│   ├── application_controller.rb
│   ├── sessions_controller.rb   # Public: login/logout
│   ├── registrations_controller.rb # Public: signup
│   ├── passwords_controller.rb  # Public: password reset
│   └── home_controller.rb       # Public: landing page
├── models/
├── views/
│   ├── dashboard/               # Views for authenticated controllers
│   │   ├── profiles/
│   │   └── businesses/
│   ├── sessions/
│   ├── registrations/
│   └── layouts/
├── javascript/
│   ├── controllers/             # Stimulus controllers
│   └── components/              # React components (for complex UI)
├── jobs/                        # Background jobs (Solid Queue)
├── mailers/
└── services/                    # Business logic services

spec/
├── models/                      # Model specs
├── requests/                    # Request/controller specs
├── factories/                   # FactoryBot factories
├── support/                     # Shared helpers
└── rails_helper.rb

lib/
└── tasks/

config/
├── deploy.yml
├── environments/
└── locales/
    ├── vi.yml                       # Common Vietnamese translations (navigation, footer, flash)
    ├── en.yml                       # Common English translations
    ├── views/
    │   ├── vi.yml                   # View-specific translations (Vietnamese)
    │   └── en.yml                   # View-specific translations (English)
    ├── controllers/
    │   ├── vi.yml                   # Controller flash messages (Vietnamese)
    │   └── en.yml                   # Controller flash messages (English)
    └── models/
        ├── vi.yml                   # Model attributes & validations (Vietnamese)
        └── en.yml                   # Model attributes & validations (English)

db/
├── migrate/
└── seeds.rb
```

---

## I18n (Internationalization) Organization

### File Structure
All translation files are organized in `config/locales/` with the following structure:

**Root Level (`config/locales/*.yml`)**
- Common translations used across the app
- Navigation, footer, common actions, flash types
- Example keys: `navigation.*`, `footer.*`, `common.actions.*`, `flash.*`

**Views (`config/locales/views/*.yml`)**
- All view-specific translations (titles, labels, placeholders, hints, buttons)
- Organized by controller namespace and action
- Example keys: `views.dashboard.businesses.show.title`, `views.sessions.new.email_placeholder`

**Controllers (`config/locales/controllers/*.yml`)**
- Controller flash messages (success, error, notice)
- Organized by controller namespace
- Example keys: `controllers.dashboard.open_hours.flash.updated`

**Models (`config/locales/models/*.yml`)**
- Model attribute names and validation messages
- Example keys: `activerecord.attributes.user.email`, `activerecord.errors.models.business.slug`

### Usage Examples

**In Controllers:**
```ruby
# ✅ CORRECT - Use controllers namespace
redirect_to path, notice: t("controllers.dashboard.open_hours.flash.updated")

# ❌ WRONG - Don't use views namespace in controllers
redirect_to path, notice: t("views.dashboard.open_hours.flash.updated")
```

**In Views:**
```erb
<!-- ✅ CORRECT - Use views namespace -->
<h1><%= t('views.dashboard.businesses.show.title') %></h1>

<!-- ✅ CORRECT - Use common namespace for shared elements -->
<button><%= t('common.actions.save') %></button>
```

### Key Naming Convention
- Use descriptive, hierarchical keys: `namespace.controller.action.element`
- Keep keys lowercase with underscores: `operating_hours_title`, not `operatingHoursTitle`
- Group related translations together in the hierarchy

---

## Domain Model & Key Features

### Core Entities

**User (Business Owner)**
- Authentication and profile management
- Owns one or more businesses
- Dashboard access for managing bookings
- **Onboarding System** (Phase 1 - Complete):
  - 5-step progressive onboarding flow
  - `onboarding_step` (1-5): Tracks current progress
  - `onboarding_completed_at`: Timestamp when all steps finished
  - Onboarding steps defined in `ONBOARDING_STEPS` constant:
    1. `user_info` - User profile (name, phone)
    2. `business` - Business profile creation
    3. `hours` - Operating hours configuration
    4. `services` - Service management
    5. `completed` - Onboarding finished
  - Key methods:
    - `onboarding_completed?` - Check if all steps finished
    - `current_onboarding_step_name` - Get current step name as symbol
    - `advance_onboarding!` - Move to next step (auto-completes on step 5)
    - `can_access_step?(step_number)` - Check if user can access step
    - `onboarding_step_complete?(step_number)` - Validate step completion

**Business**
- Business profile (name, description, address, phone)
- Operating hours (weekly schedule)
- Landing page configuration (theme, colors, layout)
- Capacity settings (how many clients can be served at once)
- Public booking URL: `thembooking.com/business-slug`

**Service** (replaces Event Type)
- Name (e.g., "Men's Haircut", "Full Body Massage")
- Duration (15, 30, 45, 60, 90, 120 minutes)
- Price (in VND)
- Description
- Active/inactive status

**Resource** (optional, for advanced capacity)
- Name (e.g., "Chair 1", "Room A", "Station 2")
- Type (chair, room, station)
- Linked to specific services (optional)

**Staff** (optional, for businesses with employees)
- Name, avatar
- Services they can perform
- Personal availability/schedule
- Linked to a business

**Booking/Appointment**
- Service booked
- Customer information (name, phone, email)
- Scheduled date and time
- Status: `pending`, `confirmed`, `in_progress`, `completed`, `cancelled`, `no_show`
- Source: `online` or `walk_in`
- Resource assigned (optional)
- Staff assigned (optional)
- Started at / Completed at timestamps

**Customer** (optional, for repeat customers)
- Name, phone, email
- Booking history
- Notes

### Key User Flows

1. **Business Setup**
   - Owner signs up and creates business profile
   - Sets operating hours (Mon-Sat 9am-7pm)
   - Adds services with duration and pricing
   - Configures capacity (e.g., 3 chairs)
   - Customizes landing page

2. **Online Booking Flow** (Customer)
   - Customer visits `thembooking.com/johns-barbershop`
   - Sees services, prices, and available times
   - Selects service and time slot
   - Enters contact info
   - Receives confirmation (email/SMS)

3. **Walk-in Management** (Owner)
   - Customer walks in without appointment
   - Owner adds them to queue from dashboard
   - System tracks wait time and position
   - Owner marks as "started" when service begins
   - Owner marks as "completed" when done

4. **Daily Operations Dashboard**
   - View today's appointments and queue
   - See current capacity (2/3 chairs occupied)
   - Mark bookings as in-progress/completed/no-show
   - Add walk-in customers quickly

5. **Notifications**
   - Booking confirmation (email/SMS)
   - Reminder before appointment
   - Real-time dashboard updates via Turbo Streams

### Business Rules
- Bookings cannot exceed business capacity at any time slot
- Operating hours define when bookings can be made
- Walk-ins share capacity with scheduled appointments
- Buffer time between services (configurable)
- Cancellation window (e.g., must cancel 2 hours before)
- No-show tracking affects customer history
- Services can only be booked during operating hours

---

## Coding Conventions & Patterns

### General Rails Conventions
- Follow standard Rails conventions unless noted otherwise
- Use Rails 8 defaults (Solid Queue, Solid Cache, Solid Cable)
- Keep controllers thin - move business logic to services/models

### Development Approach: TDD (Test-Driven Development)

**All new features MUST follow this TDD workflow:**

```
1. SPEC FIRST  → Write RSpec tests defining expected behavior
2. REVIEW      → Ask for approval before implementation
3. IMPLEMENT   → Write code to make tests pass
4. VERIFY      → Run all tests, ensure green
```

**Detailed Steps:**

1. **Define Requirements & Write Specs**
   - Understand the feature requirements
   - Create RSpec test file with all expected behaviors
   - Include happy path, edge cases, and error conditions
   - DO NOT write implementation code yet

2. **Ask for Approval**
   - Present the spec file to user for review
   - Confirm the tests capture the correct requirements
   - Adjust specs based on feedback before proceeding

3. **Implement the Logic**
   - Write minimal code to make tests pass
   - Follow RED → GREEN → REFACTOR cycle
   - Keep implementation simple and focused

4. **Run All Tests**
   - Execute `bundle exec rspec` to verify all tests pass
   - Fix any failures before considering the feature complete

**Example Workflow:**
```ruby
# Step 1: Write spec first (before any implementation)
# spec/services/bookings/check_availability_spec.rb
RSpec.describe Bookings::CheckAvailability do
  describe "#call" do
    it "returns available slots within operating hours" do
      # test code
    end

    it "excludes slots that exceed capacity" do
      # test code
    end

    it "returns empty array on closed days" do
      # test code
    end
  end
end

# Step 2: Ask user to review specs
# Step 3: Implement app/services/bookings/check_availability.rb
# Step 4: Run tests → all green
```

**When to Apply TDD:**
- New models (validations, associations, methods)
- Service objects (business logic)
- Complex controller actions
- Bug fixes (write failing test first, then fix)

### Controller Namespace Convention

Controllers are organized by authentication requirements:

**Public Controllers** (no authentication required):
- `SessionsController` - Login/logout
- `RegistrationsController` - User signup
- `PasswordsController` - Password reset
- `EmailConfirmationsController` - Email verification
- `HomeController` - Public landing page

**Dashboard Namespace** (`app/controllers/dashboard/`) - Requires authentication:
- All controllers inherit from `Dashboard::BaseController`
- `Dashboard::BaseController` inherits from `ApplicationController` (which includes Authentication)
- Routes are nested under `namespace :dashboard`

```ruby
# app/controllers/dashboard/base_controller.rb
module Dashboard
  class BaseController < ApplicationController
    # Authentication is required by default (from ApplicationController)

    def current_user
      Current.user
    end
    helper_method :current_user
  end
end

# app/controllers/dashboard/profiles_controller.rb
module Dashboard
  class ProfilesController < BaseController
    # All actions require authentication
  end
end
```

**Routes Pattern:**
```ruby
# config/routes.rb
Rails.application.routes.draw do
  # Public routes
  resource :session
  resource :registration, only: [:new, :create]
  resources :passwords, param: :token

  # Authenticated routes
  namespace :dashboard do
    resource :profile, only: [:edit, :update]
    resource :business
    # ... other authenticated resources
  end
end
```

**URL Helpers:**
- Public: `new_session_path`, `new_registration_path`
- Dashboard namespace: `edit_dashboard_profile_path`, `dashboard_business_path`

### Frontend Approach
- use tailwind css
- use the standardize classes in the application.css and follow the existed page design

**Default to server generated (app/views):**
**Use Hotwire to improve UX when:**
- Use Turbo Frames for partial page updates
- Use Turbo Streams for real-time updates
- Use Stimulus for simple interactivity

**Use React only when:**
- Complex state management is needed (e.g., availability editor with drag-drop)
- Rich interactive calendar views
- Complex form wizards with multi-step validation
- Heavy client-side data manipulation




### Service Objects
For complex business logic, use service objects:
```ruby
# app/services/bookings/create_booking.rb
module Bookings
  class CreateBooking
    def initialize(business:, service:, params:)
      @business = business
      @service = service
      @params = params
    end

    def call
      # Check capacity availability
      # Create booking record
      # Send confirmation notification
      # Return result
    end
  end
end

# app/services/bookings/check_availability.rb
module Bookings
  class CheckAvailability
    def initialize(business:, date:, service:)
      @business = business
      @date = date
      @service = service
    end

    def call
      # Check operating hours
      # Check existing bookings
      # Check capacity
      # Return available time slots
    end
  end
end
```

### Testing Approach

**Framework**: RSpec with FactoryBot, Faker, and Shoulda-Matchers

**Test Structure:**
```
spec/
├── models/          # Model unit tests (validations, associations, methods)
├── requests/        # Controller/request specs
├── services/        # Service object specs
├── factories/       # FactoryBot factory definitions
├── support/         # Shared examples, helpers
├── rails_helper.rb  # Rails test configuration
└── spec_helper.rb   # RSpec configuration
```

**Testing Requirements:**
- **Models**: All models MUST have specs covering:
  - Associations (`it { is_expected.to belong_to(:user) }`)
  - Validations (`it { is_expected.to validate_presence_of(:name) }`)
  - Enums (if any)
  - Custom methods and business logic
  - Edge cases and error conditions

- **Controllers/Requests**: Test key user flows:
  - Authentication requirements (authenticated vs public endpoints)
  - Happy path scenarios
  - Error handling and validation failures
  - Authorization (user can only access their own resources)

- **Services**: All service objects must have specs

**Factory Guidelines:**
```ruby
# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    email_address { Faker::Internet.email }
    password { "password123" }
    name { Faker::Name.name }
    email_confirmed_at { Time.current }

    trait :unconfirmed do
      email_confirmed_at { nil }
      email_confirmation_token { SecureRandom.urlsafe_base64(32) }
    end
  end
end
```

**Model Spec Example:**
```ruby
# spec/models/business_spec.rb
require "rails_helper"

RSpec.describe Business, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    subject { build(:business) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:slug).case_insensitive }
  end

  describe "#booking_url" do
    it "returns the public booking URL" do
      business = build(:business, slug: "test-shop")
      expect(business.booking_url).to eq("thembooking.com/test-shop")
    end
  end
end
```

**Running Tests:**
```bash
# Run all specs
bundle exec rspec

# Run specific spec file
bundle exec rspec spec/models/business_spec.rb

# Run with documentation format
bundle exec rspec --format documentation

# Run only failing specs
bundle exec rspec --only-failures
```

**Test Coverage Goals:**
- Models: 100% coverage for validations and associations
- Critical business logic: 100% coverage
- Controllers: Cover main flows and error cases
- Overall target: 80%+ coverage

### Code Style
- Follow Ruby community style guide
- Use Rubocop for linting (if configured)
- Prefer meaningful variable names over comments
- Keep methods short and focused (< 10 lines ideally)

---

## Deployment & Infrastructure

### Hosting Server Setup

**Architecture**: Cloud-hosted on Digital Ocean droplets

**Environments**:
- **Staging**: `thembooking.cuongnguyenfu.com`
  - Digital Ocean droplet (Singapore region)
  - 1 vCPU, 512MB RAM, 10GB SSD
- **Production**: `thembooking.com`
  - Digital Ocean droplet (Singapore region)
  - Configuration TBD based on traffic requirements

**Server Access**:
- SSH access via Digital Ocean droplet IP addresses
- Root access for server administration
- Kamal handles application deployment via Docker

**Database Configuration**:
- PostgreSQL instance running on each droplet
- PostgreSQL 14+ (managed via systemd)
- Separate database instances for staging and production
- Connection managed via `DATABASE_URL` environment variable in Kamal configuration

**Benefits of This Setup**:
- Reliable uptime with Digital Ocean infrastructure
- Singapore region for optimal performance to Vietnam market
- Scalable - easy to upgrade droplet size as traffic grows
- Predictable monthly costs (starting from $4-6/month per environment)
- No dependency on home internet connection

**Cost Considerations**:
- Staging: ~$4-6/month (Basic droplet)
- Production: ~$6-12/month initially (can scale up based on usage)
- Much cheaper than managed services like Heroku or AWS Elastic Beanstalk

### Kamal Configuration
Located in `config/kamal.yml`:
- [Describe your deployment setup]
- Server: [IP/hostname]
- Docker registry: [Docker Hub/GitHub Container Registry]
- Environment: [staging/production]

### Deployment Workflow
```bash
# Deploy to production
kamal deploy

# Deploy specific service
kamal app deploy

# Check deployment status
kamal app details

# View logs
kamal app logs -f

# Rollback
kamal app rollback
```

### Database Management
- Migrations run automatically on deploy via Kamal
- Database backups: [Describe your backup strategy]
- To run migrations manually: `kamal app exec -i --reuse rails db:migrate`

### Environment Configuration
- Production env vars managed through Kamal secrets
- Use `.env` for local development
- Use Rails credentials for sensitive keys

### Monitoring & Logging
- Application logs: Via Kamal logs
- Error tracking: [To be added - Sentry/Rollbar/etc]
- Performance monitoring: [To be added - New Relic/Scout/etc]
- Uptime monitoring: [To be added]

---

## Current Development Status

### ✅ Completed
- [x] Initial Rails 8 app setup
- [x] Kamal deployment configuration
- [x] Successfully deployed to hosting server
- [x] User authentication system (business owner login)
- [x] Email verification flow
- [x] Password reset flow
- [x] Account settings page
- [x] Controller namespace convention (Dashboard namespace)
- [x] RSpec testing setup with FactoryBot, Faker, Shoulda-Matchers
- [x] Business model foundation (schema, validations, associations)
- [x] Business profile setup (1.2) - create/edit/view business profile

### 🚧 In Progress
- [x] User onboarding system (Phase 1) - Database migrations complete
- [ ] Service management CRUD (2.1)
- [ ] Operating hours configuration (2.2)

### 📋 Planned Features (MVP)
- [ ] Capacity configuration
- [ ] Online booking flow
- [ ] Walk-in management
- [ ] Daily operations dashboard
- [ ] Real-time queue tracking
- [ ] Business landing page builder
- [ ] Email notifications
- [ ] Freemium with Sepay payment

### 📋 Post-MVP Features
- [ ] Staff management (multiple employees) - v1.1
- [ ] Customer accounts & history - v1.2
- [ ] SMS/Zalo notifications - v1.3
- [ ] Analytics dashboard - v1.4
- [ ] Multi-location support - v2.0
- [ ] Mobile app with Hotwire Native - v2.0
- [ ] Resource management (chairs, rooms) - nice-to-have, low priority

### Known Issues & Technical Debt
- [Document any known issues]
- [Note areas that need refactoring]
- [Performance concerns]

---

## External Dependencies & Integrations

### Planned Third-Party Services
- **Email**: SendGrid, Postmark, or AWS SES (booking confirmations, reminders)
- **SMS**: Twilio or local Vietnam provider (appointment reminders)
- **Payments**: Sepay for Vietnam market, Stripe for global expansion
- **File Storage**: ActiveStorage with S3/local storage (business logos, photos)
- **Calendar Export**: Google Calendar (one-way export for business owners)

### API Keys & Credentials
Managed via Rails credentials:
```bash
rails credentials:edit --environment production
```

---

## Guidelines for AI Assistance (Claude)

### Communication Preferences
- **Response Style**: Balance between detailed and concise - provide thorough explanations for complex topics, but stay focused
- **Code Examples**: Always include practical code examples when explaining concepts
- **Vietnamese Context**: I'm based in Vietnam, so consider local context when relevant (time zones, payment methods, etc.)

### Development Preferences
- **Testing**: Always suggest tests alongside implementation code
- **Security**: Highlight security considerations for authentication, data handling, payments
- **Performance**: Point out potential N+1 queries, caching opportunities
- **Mobile-First**: Consider Hotwire Native compatibility when suggesting frontend approaches

### When Helping with Code
- Prefer Rails 8 conventions and new features (Solid gems, authentication generator)
- Suggest Hotwire solutions before React unless complexity warrants it
- Consider PostgreSQL-specific features where beneficial
- Keep accessibility in mind (semantic HTML, ARIA attributes)
- Use Tailwind utility classes, avoid custom CSS unless necessary

### What to Avoid
- Don't suggest gems that duplicate Rails 8 built-in functionality (e.g., Sidekiq when we use Solid Queue)
- Don't create overly complex abstractions too early
- Don't over-engineer time zones - most businesses serve local customers
- Don't forget to consider Kamal deployment impacts when suggesting infrastructure changes
- Don't build staff/resource features until MVP is validated

### Project-Specific Context
- This is a side project, so pragmatic solutions are preferred over perfect ones
- Focus on shipping MVP features quickly, then iterate
- Cost-consciousness is important (cheaper hosting, avoid expensive services)
- Consider that I manage multiple side projects, so maintainability matters
- **Target market is Vietnam** - prioritize Vietnamese language and local payment (Sepay)
- **Service business focus** - think barber shops, salons, spas when designing features

---

## Resources & Documentation

### Project Documentation
- [Link to design docs/Figma]
- [Link to API documentation]
- [Link to user guides]

### External Resources
- [Rails 8 Release Notes](https://guides.rubyonrails.org/8_0_release_notes.html)
- [Hotwire Documentation](https://hotwired.dev/)
- [Kamal Documentation](https://kamal-deploy.org/)
- [Tailwind CSS Docs](https://tailwindcss.com/docs)

---

## Contact & Contribution

**Developer**: Cuong
**Repository**: [Your GitHub repo URL]
**Deployed App**: [Your production URL]

---

*Last Updated*: December 29, 2025
*Version*: 0.1.0 (Early Development - Service Business Focus)

---

## Notes for Future Development

### Architecture Decisions
- **Why Hotwire + selective React**: Get 90% of interactivity with Hotwire's simplicity, use React only where state complexity demands it
- **Why Kamal**: Simple, Docker-based deployment without Kubernetes complexity
- **Why Rails 8 Solid gems**: Reduce infrastructure dependencies (no Redis/Sidekiq/etc needed), lower hosting costs

### Scalability Considerations
- Start simple, optimize when needed
- PostgreSQL can handle significant load before sharding needed
- Solid Queue suitable for MVP, can migrate to Sidekiq if job volume grows
- Consider read replicas when read load increases

### Future Technical Improvements
- [ ] Add full-text search for services/businesses (pg_search)
- [ ] Implement caching strategy for availability calculations
- [ ] Consider CDN for static assets (landing page images)
- [ ] Add comprehensive monitoring and alerting
- [ ] Implement rate limiting for booking endpoints
- [ ] Real-time dashboard updates optimization (Turbo Streams)
- [ ] Queue estimation algorithm improvement
- [ ] Staff scheduling algorithm (v1.1)

# ThemBooking Codebase Summary

*Generated: December 7, 2025*

## Project Overview

**ThemBooking** is a booking and appointment management platform for service-based businesses, targeting the Vietnamese market. It's an affordable alternative to Fresha/Square Appointments, designed for barber shops, hair salons, spas, and other local service businesses.

### Key Features
- Affordable pricing (99k-299k VND/month)
- Real-time queue and walk-in management
- Beautiful, customizable business landing pages
- Simple capacity management
- Vietnamese language and local payment support (Sepay)

## Technology Stack

### Backend
- **Ruby 3.3.0** - Main language
- **Rails 8.1.1** - Web framework with modern defaults
- **PostgreSQL** - Primary database
- **Solid Cache** - Redis-less caching
- **Solid Queue** - Background job processing
- **Solid Cable** - WebSocket connections
- **Puma** - Web server
- **Active Storage** - File handling
- **BCrypt** - Authentication

### Frontend
- **Turbo Rails** - SPA-like page acceleration
- **Stimulus Rails** - JavaScript framework
- **Importmap Rails** - ES module management
- **Tailwind CSS** - Utility-first styling
- **Propshaft** - Asset pipeline

### Development & Deployment
- **RSpec** - Testing framework
- **FactoryBot** - Test data factories
- **Faker** - Fake data generation
- **Shoulda-Matchers** - RSpec matchers
- **RuboCop** - Code linting
- **Kamal** - Docker-based deployment
- **Mission Control Jobs** - Job monitoring

### Database
- PostgreSQL 14+ with UTF-8 encoding
- JSONB columns for flexible data storage
- Proper indexing for performance
- Foreign key constraints

## Project Structure

```
thembooking_com/
├── app/                    # Main application code
│   ├── controllers/       # Controllers
│   │   ├── application_controller.rb
│   │   ├── dashboard/      # Authenticated namespace
│   │   │   ├── base_controller.rb
│   │   │   ├── onboarding_controller.rb
│   │   │   └── ...
│   │   ├── sessions_controller.rb
│   │   ├── registrations_controller.rb
│   │   └── ...
│   ├── models/            # Active Record models
│   ├── views/             # View templates
│   ├── javascript/        # JavaScript files
│   │   ├── controllers/    # Stimulus controllers
│   │   └── application.js
│   ├── helpers/           # View helpers
│   ├── mailers/           # Email templates
│   ├── services/          # Business logic services
│   └── jobs/              # Background jobs
├── config/                # Configuration files
│   ├── environments/      # Environment-specific configs
│   ├── initializers/      # Rails initializers
│   ├── locales/           # I18n translations
│   └── routes.rb          # Route definitions
├── db/                    # Database files
│   ├── migrate/           # Database migrations
│   ├── seeds.rb           # Seed data
│   └── structure.sql      # Database schema
├── spec/                  # Test files
│   ├── models/            # Model tests
│   ├── requests/          # Controller tests
│   ├── services/          # Service tests
│   └── support/           # Test helpers
├── public/                # Static assets
├── storage/               # Active Storage files
├── log/                   # Application logs
└── tmp/                   # Temporary files
```

## Key Models

### User
```ruby
# Business owner account
class User < ApplicationRecord
  has_secure_password
  has_one :business
  has_many_attached :avatars

  # Onboarding tracking
  enum onboarding_step: { user_info: 1, business: 2, hours: 3, services: 4, completed: 5 }
end
```

### Business
```ruby
# Business profile
class Business < ApplicationRecord
  belongs_to :user
  has_many :services
  has_one_attached :logo

  # Flexible operating hours stored as JSONB
  serialize :operating_hours, JSON

  # Business types
  enum business_type: { barber: 0, salon: 1, spa: 2, nail: 3, other: 4 }
end
```

### Service
```ruby
# Bookable service offering
class Service < ApplicationRecord
  belongs_to :business

  # Duration in minutes
  enum duration: { fifteen: 15, thirty: 30, forty_five: 45, sixty: 60, ninety: 90, one_twenty: 120 }

  # Price handling
  monetize :price_cents
end
```

## Authentication System

### Built-in Rails 8 Authentication
- No Devise dependency
- Custom controllers with email/password auth
- Email verification flow
- Password reset functionality

### Security Features
- BCrypt for password hashing
- Session management with Rails
- CSRF protection
- Parameter filtering
- Secure password policies

## Onboarding System (Phase 3)

### Implementation Details
- **Progressive 4-step wizard**
- **State tracking** in database (`onboarding_step`)
- **Form validation** with proper error handling
- **Responsive design** with Tailwind CSS
- **Stimulus controllers** for interactivity

### Step Breakdown
1. **User Information** - Profile details
2. **Business Setup** - Business profile and config
3. **Operating Hours** - Weekly schedule
4. **Services** - Service offerings

## Frontend Architecture

### Server-Side Rendering
- Primary approach for performance
- Hotwire for enhanced UX
- Minimal JavaScript required

### Stimulus Controllers
- `onboarding_hours_controller.js` - Hours form toggles
- `onboarding_services_controller.js` - Dynamic service management
- Event-driven architecture

### Tailwind CSS
- Custom design system
- Responsive utilities
- Component-based styling

## Testing Strategy

### RSpec Configuration
```ruby
# spec/rails_helper.rb
RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  # Shoulda matchers
  config.include Shoulda::Matchers::ActiveModel, type: :model
  config.include Shoulda::Matchers::ActiveRecord, type: :model
end
```

### Test Coverage
- **Models**: Validations, associations, custom methods
- **Controllers**: Authentication, authorization, flows
- **Services**: Business logic unit tests
- **Integration**: End-to-end scenarios

### Factory Setup
```ruby
# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    email_address { Faker::Internet.email }
    password { "password123" }
    name { Faker::Name.name }
    email_confirmed_at { Time.current }
  end
end
```

## Database Schema

### Key Tables
```sql
Users:
  - id (bigint, primary key)
  - email_address (string, unique)
  - password_digest (string)
  - name (string)
  - phone (string)
  - onboarding_step (integer, default: 1)
  - onboarding_completed_at (datetime)
  - created_at, updated_at (timestamps)

Businesses:
  - id (bigint, primary key)
  - user_id (bigint, foreign key)
  - name (string)
  - business_type (string)
  - slug (string, unique)
  - phone (string)
  - capacity (integer)
  - address (string)
  - description (text)
  - operating_hours (jsonb)
  - created_at, updated_at (timestamps)

Services:
  - id (bigint, primary key)
  - business_id (bigint, foreign key)
  - name (string)
  - duration_minutes (integer)
  - price_cents (integer)
  - active (boolean, default: true)
  - created_at, updated_at (timestamps)
```

## Deployment Configuration

### Kamal Setup
```yaml
# config/deploy.yml
service: thembooking
image: ghcr.io/username/thembooking_com
servers:
  production: mypc.cuongnguyenfu.com:22
  staging: staging.thembooking.com:22

# Environment variables and secrets
```

### Infrastructure
- Self-hosted on local PC server
- Cloudflare Tunnel for secure access
- PostgreSQL shared database
- Docker containers
- Kamal deployment

## Environment Setup

### Prerequisites
- Ruby 3.3.0 (via asdf)
- Node.js 20.x (via asdf)
- PostgreSQL 14+
- Redis 6+ (for Solid Cache)

### Installation
```bash
# Clone repository
git clone [repository-url]
cd thembooking

# Install dependencies
bundle install
yarn install

# Setup database
rails db:create db:migrate db:seed

# Start development
bin/dev
```

### Environment Variables
```bash
# .env file
DATABASE_URL=postgresql://localhost/thembooking_development
REDIS_URL=redis://localhost:6379/0
SECRET_KEY_BASE=[generated]
```

## API Endpoints

### Public Routes
```
POST   /sessions                    # User login
DELETE /sessions                    # User logout
POST   /registrations                # User signup
POST   /passwords                    # Password reset
GET    /passwords/:token/edit        # Reset password
```

### Authenticated Routes (Dashboard)
```
GET    /dashboard/profile            # Edit profile
PATCH  /dashboard/profile            # Update profile
GET    /dashboard/business            # Edit business
PATCH  /dashboard/business            # Update business
GET    /dashboard/onboarding          # Show onboarding step
PATCH  /dashboard/onboarding          # Update onboarding step
```

## Performance Considerations

### Caching Strategy
- Solid Cache for Rails caching
- Query caching for expensive operations
- Fragment caching for view components

### Database Optimization
- Proper indexing on frequently queried columns
- Database connection pooling
- Read replica support for scaling

### Asset Optimization
- Propshaft for efficient asset serving
- Image compression and resizing
- CDN integration for static assets

## Security Best Practices

### Input Sanitization
- Rails parameter filtering
- HTML escaping in views
- XSS prevention helpers

### Authentication
- Secure password hashing
- Session management
- CSRF protection

### Authorization
- Controller-level authentication
- Resource ownership validation
- Role-based access control (future)

## Future Enhancements

### Phase 4: Booking Engine
- Online booking flow
- Availability calculation
- Customer management

### Phase 5: Features
- Landing page builder
- Email notifications
- Payment integration

### Technical Improvements
- Staff management
- Resource tracking
- Advanced analytics
- Multi-language support

## Maintenance Guidelines

### Code Quality
- Follow Rails conventions
- Keep controllers thin
- Move business logic to services
- Maintain test coverage

### Documentation
- Update with new features
- Document API changes
- Keep README current

### Monitoring
- Application logs
- Error tracking (future)
- Performance metrics
- Database health

## Contributing

### Development Workflow
1. Create feature branch
2. Write tests (TDD)
3. Implement feature
4. Run all tests
5. Submit pull request

### Code Standards
- Follow Rails style guide
- Use meaningful variable names
- Keep methods focused (< 10 lines)
- Add appropriate comments

## Support

For issues and questions:
- Developer: Cuong Nguyen
- Email: [cuong@email.com]
- Repository: [GitHub Repository]
- Production: thembooking.com

---

*Last Updated*: December 7, 2025
*Version*: 1.0.0 (Phase 3 - Onboarding Complete)
# ThemBooking System Architecture (Modular Structure)

This documentation has been reorganized into a modular structure for better maintainability.

## Navigate to Specific Topics

- **[Architecture Overview](./system-architecture/index.md)** - Start here for high-level overview
- **[Data Architecture](./system-architecture/data-architecture.md)** - Database schema, relationships, and optimization strategies
- **[Application Architecture](./system-architecture/application-architecture.md)** - Controllers, services, and domain models
- **[Security Architecture](./system-architecture/security-architecture.md)** - Authentication, authorization, and data protection
- **[Performance Architecture](./system-architecture/performance-architecture.md)** - Caching, query optimization, and background jobs
- **[Deployment & Infrastructure](./system-architecture/deployment-infrastructure.md)** - Docker, Kamal, and deployment strategy

## Quick Reference

### Phases 1-4: Multi-Location Support (COMPLETED)
### Phase 5: Service Category Management (COMPLETED)
### Phases 1-6: Business Landing Page (COMPLETED)

The architecture has been fully updated to support multiple business locations with service organization:

**Phase 1: Data Model**
- **Business**: Now a brand entity only (name, type, description, logo)
- **Branch**: Physical location with slug, address, phone, operating_hours, capacity, active status
- **Services, Bookings, BusinessClosures**: All now belong to Branch instead of Business
- Data migration: Existing businesses get auto-created "Main Branch" with all data

**Phase 2: Dashboard CRUD**
- Branch management interface with full CRUD operations
- Nested routes: `dashboard_branch_services`, `dashboard_branch_bookings`, etc.
- Branch activation/deactivation controls

**Phase 3: Public Booking Page**
- Public booking route changed from `/:business_slug` to `/:branch_slug`
- BookingsController updated to load branch by slug
- React components updated to display branch info + business branding
- All JS files updated for `branchSlug` parameter

**Phase 4: Comprehensive Testing**
- 316 tests passing (0 failures)
- Full coverage for Branch model, Dashboard CRUD, and public booking flow
- Factory updates and service spec updates complete
- System test fixes: Capybara session reset, flash accessibility, field labels

**Phase 5: Service Category Management (COMPLETED)**
- **Service Categories**: New model with branch-scoping, unique name validation, position ordering
- **Dashboard CRUD**: Full interface for managing categories, assigning/reassigning services
- **Service Form Integration**: Category dropdown + inline quick-create (Stimulus + JSON API)
- **Internationalization**: Complete i18n support (en.yml + vi.yml)
- **Test Coverage**: 338 passing tests with model, request, and integration specs

**Phase 6: Business Landing Page (COMPLETED)**
- **Phase 5: Branch Picker Modal** — Modal component with real-time open/closed status badges, Escape/backdrop close, scroll lock, focus management
- **Phase 6: Dashboard Landing Page Editor** — Full CRUD interface for business owners to customize landing page (slug, headline, description, theme color, cover photo, section toggles, custom CTA)
- **Features**: Live preview link, color picker, section visibility controls, cover photo upload with preview
- **Test Coverage**: 10 comprehensive landing page editor specs, all passing

**Features Enabled**:
- Multiple locations per business
- Service organization into categories per branch
- Branch-scoped availability checking and capacity management
- Branch-specific operating hours and closures
- Public booking URL: `/branch-slug` (branch-level routing)
- Dashboard: Branch-level service categories, service, booking, and closure management

### Key Models

```
User → Business (1:1)
Business → Branches (1:N)
Branch → Services (1:N)
Branch → ServiceCategories (1:N)
ServiceCategory → Services (0:N optional)
Branch → Bookings (1:N)
Branch → BusinessClosures (1:N)
```

### Slug Routing Strategy (Business Landing Pages)
- **Business Slug**: Public URL identifier for landing pages (e.g., `/acme-salon`)
- **Branch Slug**: Public URL identifier for booking pages (e.g., `/acme-downtown`)
- **Cross-table Uniqueness**: Both slugs must be globally unique via `SlugUniquenessValidator`
- **Implementation**: Single catch-all controller queries Business first, then Branch
- **Auto-generation**: Business slugs auto-generated from business name; Branch slugs auto-generated from branch name

### Tech Stack

- **Backend**: Rails 8.0.0, Ruby 3.3.0, PostgreSQL 14+, Redis 6+
- **Frontend**: Hotwire (Turbo + Stimulus), Tailwind CSS, selective React
- **Deployment**: Kamal (Docker), self-hosted with Cloudflare Tunnel

*Last Updated*: March 25, 2026
*Version*: v0.3.2 (Business Landing Page Complete - All 6 Phases)

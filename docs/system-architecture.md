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

The architecture has been fully updated to support multiple business locations:

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

**Features Enabled**:
- Multiple locations per business
- Branch-scoped availability checking and capacity management
- Branch-specific operating hours and closures
- Public booking URL: `/branch-slug` (branch-level routing)
- Dashboard: Branch-level service, booking, and closure management

### Key Models

```
User → Business (1:1)
Business → Branches (1:N)
Branch → Services (1:N)
Branch → Bookings (1:N)
Branch → BusinessClosures (1:N)
```

### Tech Stack

- **Backend**: Rails 8.0.0, Ruby 3.3.0, PostgreSQL 14+, Redis 6+
- **Frontend**: Hotwire (Turbo + Stimulus), Tailwind CSS, selective React
- **Deployment**: Kamal (Docker), self-hosted with Cloudflare Tunnel

*Last Updated*: March 21, 2026
*Version*: v0.2.2 (Modular Structure + Multi-Location Complete & Tested)

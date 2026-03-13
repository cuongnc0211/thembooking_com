# Project Changelog

All notable changes to ThemBooking project are documented here.

## [Unreleased]

### Added
- **[2026-03-13] Phase 1: Multi-Location Architecture (Documentation Update)** — Refactored system architecture docs for Branch model
  - **New Model**: `Branch` (physical location) with slug, address, phone, operating_hours (JSONB), capacity, active status, position
  - **New Structure**: Modular architecture documentation in `/docs/system-architecture/` directory
    - `index.md` — Overview and navigation
    - `data-architecture.md` — Database schema and optimization
    - `application-architecture.md` — Controllers, services, models
    - `security-architecture.md` — Auth, authorization, data protection
    - `performance-architecture.md` — Caching, query optimization, background jobs
    - `deployment-infrastructure.md` — Docker, Kamal, deployment strategy
  - **Updated**: `codebase-summary.md` with Phase 1 architecture changes
  - **Reference**: Main `system-architecture.md` now points to modular docs

- **[2026-03-12] Admin Staffs CRUD Management** — Full staff account management for super admins
  - **New Controller**: `Admin::StaffsController` with full CRUD operations
  - **New Views**: index (with search/pagination), show, new, edit, _form partial
  - **New Routes**: `resources :staffs` under admin namespace
  - **Features**: Staff search by name/email, pagination (25 per page), role management, password handling, self-deletion prevention
  - **Access Control**: Super-admin role required (`require_super_admin!` before_action)
  - **Test Coverage**: 31 passing request specs

### Changed
- **[2026-03-13] Architecture Model Refactoring for Multi-Location Support** — Data model shifted from business-centric to location-centric
  - **Business**: Now brand entity only (name, business_type, description, logo). Has_many branches.
  - **Branch**: Physical location with all location-specific data (slug, address, phone, operating_hours, capacity). Belongs_to business.
  - **Services, Bookings, BusinessClosures**: Now belong_to :branch (not :business)
  - **Public Booking URL**: Changed from `/business-slug` to `/branch-slug` (branch-level)
  - **Availability Checks**: `Bookings::CheckAvailability` now accepts `branch:` parameter; respects branch-level capacity and hours
  - **Rationale**: Enables multi-location support while maintaining data isolation per physical location

- **[2026-03-12] Refactored Booking Availability System** — Replaced pre-generated `Slot`/`BookingSlot` system with direct overlap queries
  - **Removed**: `Slot` model, `BookingSlot` model, `Slots::GenerateForBusiness` service, `GenerateDailySlotsJob`
  - **Added**: `BusinessClosure` model for managing holiday/closure dates with optional reason
  - **Modified**: `Bookings::CheckAvailability` now queries `bookings` table directly for overlapping bookings (PostgreSQL range overlap: `scheduled_at < end_time AND end_time > start_time`)
  - **Modified**: `Bookings::CreateBooking` now uses PostgreSQL advisory locks (`pg_try_advisory_xact_lock`) to serialize concurrent bookings per branch
  - **Modified**: `Booking` model — added `end_time` stored column (required), removed slot associations
  - **Modified**: `Business` model — added `has_many :business_closures`, removed `has_many :slots`
  - **Rationale**: Simpler, more maintainable design (YAGNI). Eliminates job scheduling complexity and slot capacity management bugs.
  - **Availability Logic**: Respects `operating_hours` JSONB (including breaks), `business_closures` table (holidays), and branch `capacity` limit
  - **Backward Compatibility**: No public API breaking changes; internal refactor

### Technical Notes
- Dashboard UI added for business owners to manage closure dates (`/dashboard/business_closures`)
- Advisory lock approach handles race conditions without exclusive slot locks
- All specs updated; no slot-related tests remain
- Database indexes updated for branch-scoped queries: `idx_bookings_overlap_check(branch_id, scheduled_at, end_time)`
- Schema migration: Service, Booking, BusinessClosure FK changed from `business_id` to `branch_id`

---

## Previous Releases

### [2026-03-01] Admin Panel & CRUD Management
- Implemented admin panel with authentication
- Added admin users management (CRUD)
- Added admin businesses management (CRUD)
- Admin request specs for data validation

### [2026-02-15] Authentication & Onboarding Completion
- Reskinned sign-in and sign-up pages with dark theme
- Completed onboarding system (4-step wizard)
- Enhanced session management
- Rate limiting on authentication endpoints

### [2026-01-15] Initial Project Setup
- Rails 8.0.0 application scaffold
- PostgreSQL database setup
- Authentication system (email/password)
- User onboarding framework (4-step wizard)
- Business profile management
- Dashboard base structure

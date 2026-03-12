# Project Changelog

All notable changes to ThemBooking project are documented here.

## [Unreleased]

### Changed
- **[2026-03-12] Refactored Booking Availability System** — Replaced pre-generated `Slot`/`BookingSlot` system with direct overlap queries
  - **Removed**: `Slot` model, `BookingSlot` model, `Slots::GenerateForBusiness` service, `GenerateDailySlotsJob`
  - **Added**: `BusinessClosure` model for managing holiday/closure dates with optional reason
  - **Modified**: `Bookings::CheckAvailability` now queries `bookings` table directly for overlapping bookings (PostgreSQL range overlap: `scheduled_at < end_time AND end_time > start_time`)
  - **Modified**: `Bookings::CreateBooking` now uses PostgreSQL advisory locks (`pg_try_advisory_xact_lock`) to serialize concurrent bookings per business
  - **Modified**: `Booking` model — added `end_time` stored column (required), removed slot associations
  - **Modified**: `Business` model — added `has_many :business_closures`, removed `has_many :slots`
  - **Rationale**: Simpler, more maintainable design (YAGNI). Eliminates job scheduling complexity and slot capacity management bugs.
  - **Availability Logic**: Respects `operating_hours` JSONB (including breaks), `business_closures` table (holidays), and business `capacity` limit
  - **Backward Compatibility**: No public API breaking changes; internal refactor

### Technical Notes
- Dashboard UI added for business owners to manage closure dates (`/dashboard/business_closures`)
- Advisory lock approach handles race conditions without exclusive slot locks
- All specs updated; no slot-related tests remain
- Database indexes added for overlap check performance: `idx_bookings_overlap_check(business_id, scheduled_at, end_time)`

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

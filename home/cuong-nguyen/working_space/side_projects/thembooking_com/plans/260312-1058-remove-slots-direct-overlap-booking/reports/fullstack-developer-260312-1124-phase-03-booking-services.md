# Phase Implementation Report

## Executed Phase
- Phase: phase-03-booking-services
- Plan: plans/260312-1058-remove-slots-direct-overlap-booking
- Status: completed

## Files Modified

| File | Changes |
|------|---------|
| `app/services/bookings/check_availability.rb` | Full rewrite — direct overlap query, break/closure guards |
| `app/services/bookings/create_booking.rb` | Full rewrite — advisory lock, overlap count, no Slot/BookingSlot |
| `app/controllers/bookings_controller.rb` | Removed stale slot comments, dead hash/struct dual-handling, simplified result access |
| `app/models/booking.rb` | Added `return if end_time.present?` guard to `compute_end_time` |

## Tasks Completed
- [x] Rewrite `app/services/bookings/check_availability.rb`
- [x] Rewrite `app/services/bookings/create_booking.rb`
- [x] Audit `app/controllers/bookings_controller.rb` — no Slot/BookingSlot refs; removed dead dual-format result handling
- [x] Fix `compute_end_time` callback guard (`return if end_time.present?`)
- [x] Smoke test: `CheckAvailability OK, slots: 31`
- [x] Advisory lock query verified: `pg_try_advisory_xact_lock(1)` returns true

## Tests Status
- Smoke test: PASS (31 slots returned for business with capacity=2, full operating_hours)
- Advisory lock: PASS
- Type check: N/A (Ruby)
- Unit tests: not run (Phase 06 scope)

## compute_end_time Callback — Key Finding

The original callback had no guard and would overwrite any explicitly-set `end_time`. At `before_save` time, `services.sum(:duration_minutes)` issues a SQL query against `booking_services` — which don't exist yet for a new unsaved booking (join records saved after `booking.save!`). Result: callback would compute `0` minutes duration and set `end_time = scheduled_at`, corrupting the value.

Fix: added `return if end_time.present?` as first guard — `CreateBooking` sets `end_time` explicitly before `save!`, callback is skipped. Walk-in/admin-created bookings that don't pre-set `end_time` still compute it via callback after services are associated (existing behavior).

## Issues Encountered
- None. Controller had no `Slot`/`BookingSlot` references — only stale comments and dead dual-format result code.

## Next Steps
- Phase 04: cleanup dead code (Slot/BookingSlot model files, migrations, etc.)
- Phase 06: write unit/integration tests for new service behavior

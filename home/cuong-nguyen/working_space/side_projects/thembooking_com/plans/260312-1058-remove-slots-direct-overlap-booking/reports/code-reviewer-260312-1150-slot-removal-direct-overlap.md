# Code Review: Slot System Removal — Direct Overlap Booking

**Date:** 2026-03-12
**Branch:** staging
**Reviewer:** code-reviewer agent

---

## Scope

- `app/models/business_closure.rb`
- `app/models/booking.rb` (end_time + compute_end_time)
- `app/models/business.rb` (has_many :business_closures)
- `app/services/bookings/check_availability.rb`
- `app/services/bookings/create_booking.rb`
- `app/controllers/dashboard/business_closures_controller.rb`
- `app/views/dashboard/business_closures/index.html.erb`
- `db/migrate/20260312042059_add_end_time_to_bookings.rb`
- `db/migrate/20260312042103_create_business_closures.rb`
- `db/migrate/20260312042104_drop_slots_and_booking_slots.rb`

---

## Overall Assessment

The implementation is directionally correct and well-structured — YAGNI/KISS goals achieved. The core overlap query is correct, auth is scoped via `current_user.business`, and the migration backfill is safe. There are two correctness issues that need fixing before this is production-ready, and a handful of lower-priority items.

**Score: 7/10** — Solid foundation, two bugs to fix.

---

## Critical Issues (must fix)

### C1 — `compute_end_time` fires on every update, silently wrong after service changes

**File:** `app/models/booking.rb:55-61`

```ruby
def compute_end_time
  return if end_time.present?   # <-- THIS IS THE BUG
  ...
end
```

The guard `return if end_time.present?` means `end_time` is **never recalculated** once set. This is correct for the create path (where `CreateBooking` sets it explicitly), but breaks any update path where services change. Example: admin reschedules a booking from a 30-min service to a 60-min service — `end_time` stays at the old value, overlap checks will be wrong.

**Fix options:**
1. Remove the callback entirely — `CreateBooking` already sets `end_time` explicitly, which is the only code path that needs it. Admin/walk-in update paths should also set `end_time` explicitly in their respective services/controllers.
2. Or change guard to only skip when `end_time_changed? == false && !scheduled_at_changed? && !services.loaded?` — but this is complex and error-prone.

**Recommended:** Remove the `before_save :compute_end_time` callback. Make `end_time` a field that must be explicitly managed by service objects. Add a model-level validation `validates :end_time, presence: true` to enforce this contract.

---

### C2 — Advisory lock: non-blocking strategy silently drops concurrent bookings with no user feedback

**File:** `app/services/bookings/create_booking.rb:31-33`

```ruby
unless locked
  raise ActiveRecord::Rollback  # transaction silently rolls back
end
```

When `pg_try_advisory_xact_lock` returns false (lock already held by concurrent request), the code raises `ActiveRecord::Rollback`. The calling code then falls through to:

```ruby
error_msg = booking&.errors&.full_messages&.join(", ") || "Time slot no longer available."
```

`booking` is `nil` at this point, so the error message correctly says "Time slot no longer available." However, the **actual cause is lock contention**, not capacity being full. The user is told the slot is unavailable when in fact the concurrent booking might have left capacity free — they would need to retry. This is a UX/correctness issue under moderate concurrency.

**More importantly:** `pg_try_advisory_xact_lock` is **session-scoped** by ID. Business IDs are small integers (1, 2, 3...). These are 32-bit integers; the function signature is `pg_try_advisory_xact_lock(bigint)`. Passing `@business.id.to_i` works, but **two different businesses could collide** if `business.id` values are reused as lock keys globally — this is fine as long as IDs are unique across the system (they are, PK). No collision risk here, just note it.

**Real concern:** The lock should ideally retry once rather than immediately failing the booking. Consider `pg_try_advisory_xact_lock` with a short retry loop or switch to `pg_advisory_xact_lock` (blocking) — the transaction is short so blocking is acceptable.

---

## High Priority (should fix)

### H1 — `compute_end_time` when `services` not loaded produces N+1 or 0-duration booking

**File:** `app/models/booking.rb:59`

```ruby
duration = services.sum(:duration_minutes)
```

If the booking is new and `services` haven't been assigned yet at callback time (e.g., a new Booking object before `booking.services = services` is called), this returns 0. `end_time` would equal `scheduled_at`, making every overlap query treat the booking as zero-width — it would never match any overlap check. This is actually a timing issue: `before_save` fires before `has_many :through` records are written, so `services.sum` on a new unsaved booking may return 0 depending on the association state.

`CreateBooking` avoids this by setting `end_time` explicitly before save — but this is a subtle trap for any future developer who creates a `Booking` directly (e.g., in tests, seeds, or admin interfaces).

---

### H2 — Backfill fallback assigns 30-minute duration to bookings with 0-duration services

**File:** `db/migrate/20260312042059_add_end_time_to_bookings.rb:18`

```sql
UPDATE bookings SET end_time = scheduled_at + INTERVAL '30 minutes' WHERE end_time IS NULL
```

The first UPDATE correctly sets `end_time = scheduled_at + 0 minutes` for bookings whose services sum to 0 (i.e., `end_time = scheduled_at`). But that satisfies `end_time IS NOT NULL`, so the fallback doesn't fire for those. Actually — for bookings with `scheduled_at IS NOT NULL` and no services: first UPDATE sets `end_time = scheduled_at + 0 = scheduled_at` (since COALESCE(SUM, 0) = 0). Then `change_column_null :bookings, :end_time, false` enforces NOT NULL. The fallback `WHERE end_time IS NULL` only catches bookings where `scheduled_at IS NULL` — that's the only gap.

**Wait — the logic is actually correct** as written, but the comment is misleading: the fallback isn't for "0 duration" bookings, it's for `scheduled_at IS NULL` bookings. These shouldn't exist given the model validation, but it's a safe guard. No bug here, just a misleading comment.

---

### H3 — `CheckAvailability`: `SLOT_INTERVAL = 15.minutes` constant is dead code

**File:** `app/services/bookings/check_availability.rb:3`

The constant `SLOT_INTERVAL` is used in `generate_candidate_times` at line 59. So it is used — not dead code. However, it still couples the slot-free availability service to the old slot paradigm conceptually. Rename to `AVAILABILITY_INTERVAL` or `STEP_INTERVAL` for clarity. Minor.

---

### H4 — `available_at?` does not account for timezone when querying bookings

**File:** `app/services/bookings/check_availability.rb:78-83`

```ruby
.where("scheduled_at < ? AND end_time > ?", end_time, start_time)
```

`start_time` and `end_time` are `Time.zone` objects from `parse_time_on_date`, so timezone is handled. This is fine as long as `bookings.scheduled_at` is stored in UTC (Rails default) and `Time.zone` is set correctly per request. Verify `config.time_zone` and that `scheduled_at` columns are `timestamp with time zone` or consistently UTC. Not a bug, but worth confirming.

---

## Medium Priority

### M1 — `destroy` action has no error handling

**File:** `app/controllers/dashboard/business_closures_controller.rb:18-21`

```ruby
def destroy
  closure = current_user.business.business_closures.find(params[:id])
  closure.destroy
  redirect_to ...
end
```

`closure.destroy` can fail (returns false) if callbacks or validations prevent it. No check on the return value. Should be `closure.destroy!` and rescue, or check `closure.destroy` and render error. Low risk currently (no destroy callbacks on the model) but fragile.

---

### M2 — `BusinessClosure` date validation only on create — allows past dates on update

**File:** `app/models/business_closure.rb:7`

```ruby
validate :date_not_in_past, on: :create
```

If a closure is updated via API or admin (not possible via current UI but possible in future), the date could be changed to a past date. This is acceptable given current UI scope, just note it.

---

### M3 — `generate_candidate_times` returns `Time` objects but callers treat them as displayable times

**File:** `app/services/bookings/check_availability.rb:48-63`

The method returns `Time` objects. The booking controller presumably serializes these for JSON or view. Confirm the booking booking form correctly formats these for display and submission. Not reviewed here (controller not in scope) but worth verifying.

---

### M4 — Missing index on `business_closures.date` for scalar date lookups

**File:** `db/migrate/20260312042103_create_business_closures.rb`

The migration adds a composite unique index on `[:business_id, :date]`. This covers `business_closed_on_date?` queries which filter `WHERE business_id = ? AND date = ?` — the composite index serves this. No issue.

---

## Low Priority

### L1 — `DropSlotsAndBookingSlots#down` recreates slots without data — misleading rollback

The `down` migration recreates the schema but loses all slot/booking_slot data. This is typical for destructive migrations, but there's no comment warning about data loss on rollback. Consider a comment.

### L2 — `Result = Struct.new(...)` defined but not used in `CreateBooking`

**File:** `app/services/bookings/create_booking.rb:3`

`Result = Struct.new(:success?, :booking, :error)` is defined but `call` returns a plain hash `{ success: true, ... }`. Either use the Struct or remove it. Minor inconsistency.

### L3 — `SLOT_INTERVAL` naming (see H3 above)

---

## Edge Cases Found

| Case | Risk | Location |
|------|------|----------|
| `service.duration_minutes = 0` | `generate_candidate_times` generates infinite candidates if step = 0; `SLOT_INTERVAL` prevents this since step is 15min not duration. But `available_at?` query would have `end_time = start_time` — never overlaps anything, always available. Silent wrong result. | `check_availability.rb:20,67` |
| `nil scheduled_at` passed to `CreateBooking` | `@start_time = nil`, then `end_time = nil + duration.minutes` raises `NoMethodError` | `create_booking.rb:9,20` |
| Business with `operating_hours = nil` | `operating_hours_for_date` returns nil, `call` returns `[]` — handled correctly | `check_availability.rb:17` |
| `operating_hours[day]` missing (key not present) | `&.dig` returns nil, `call` returns `[]` — handled correctly | `check_availability.rb:34` |
| Empty `service_ids` array with `service: nil` | `calculate_total_duration` returns 0, `call` returns `[]` — handled | `check_availability.rb:13` |
| Concurrent bookings: lock returns false | Silent "slot unavailable" with no retry — user must re-submit manually | `create_booking.rb:31` |

**Zero-duration service (L2 above) needs explicit guard:**
```ruby
return [] if total_duration.zero?  # already present at line 20 — CORRECT
```
Actually line 20 already handles this: `return [] if total_duration.zero?`. The zero-duration risk is already mitigated in `CheckAvailability`. However `CreateBooking` does NOT guard against it — if `total_duration = 0`, `end_time = start_time`, and the booking would be created with zero duration, which passes all overlap checks trivially. This is a **real bug** if a zero-duration service exists.

---

## Positive Observations

- IDOR risk is absent: `current_user.business.business_closures.find(params[:id])` scopes to user's business — correctly prevents cross-business access.
- The overlap query `WHERE scheduled_at < end_time AND end_time > start_time` is the standard interval overlap formula and is correct.
- The composite index `idx_bookings_overlap_check` on `[:business_id, :scheduled_at, :end_time]` directly supports the overlap query.
- `pg_try_advisory_xact_lock` is auto-released at transaction end — no orphaned locks.
- `business_closures.find(params[:id])` in destroy uses scoped association — safe from IDOR.
- Migration backfill SQL is correct and includes a NOT NULL enforcement step after backfill.
- `drop_slots_and_booking_slots.rb` `down` correctly recreates the schema for rollback.

---

## Recommended Actions (priority order)

1. **[C1]** Remove `before_save :compute_end_time` callback OR change guard. Add `validates :end_time, presence: true` to enforce service objects set it.
2. **[C2/H0]** Guard against `nil @start_time` in `CreateBooking#call` — raise or return error if `@start_time.nil?`.
3. **[C2]** Add explicit guard in `CreateBooking` for `total_duration.zero?` — return error_result.
4. **[M1]** Use `closure.destroy!` with rescue in the destroy action.
5. **[L2]** Remove unused `Result` Struct or use it consistently.
6. **[L1]** Add data-loss warning comment to `DropSlotsAndBookingSlots#down`.

---

## Unresolved Questions

1. Is there a walk-in booking code path that bypasses `CreateBooking`? If so, it must also set `end_time` explicitly — otherwise `compute_end_time` removal (C1 fix) would leave those bookings with null `end_time`, violating the NOT NULL constraint added in migration.
2. What happens when `pg_try_advisory_xact_lock` returns false and the user sees "slot unavailable" — is there a frontend retry mechanism or will users lose the slot?
3. Is `Time.zone` set per-request (e.g., from business timezone) or globally? Slot times in `CheckAvailability` use `Time.zone.parse` — if businesses are in different timezones, availability windows may be calculated wrong.

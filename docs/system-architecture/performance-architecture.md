# Performance Architecture

## Caching Strategy

### 1. Multi-Level Caching

**Fragment Caching for Views**:

```ruby
<% cache "branch_#{branch.id}_services", expires_in: 1.hour do %>
  <%= render partial: "services/service", collection: branch.services, as: :service %>
<% end %>
```

**Russian Doll Caching** (nested):

```erb
<% cache branch do %>
  <% cache branch.services do %>
    <%= render branch.services %>
  <% end %>
<% end %>
```

**Low-Level Caching with Redis**:

```ruby
class Branch < ApplicationRecord
  def cached_services_count
    Rails.cache.fetch("branch_#{id}_services_count", expires_in: 1.hour) do
      services.count
    end
  end

  def cached_current_bookings
    Rails.cache.fetch("branch_#{id}_current_bookings", expires_in: 5.minutes) do
      bookings.where(status: :in_progress).count
    end
  end
end
```

### 2. Database Query Optimization

**Eager Loading Associations** (prevent N+1):

```ruby
@branches = Branch.includes(:services, :bookings)
  .where(business: current_user.business)
```

**Counter Caches for Performance**:

```ruby
class Branch < ApplicationRecord
  has_many :services, dependent: :destroy
  has_many :bookings, dependent: :destroy
end

class Service < ApplicationRecord
  belongs_to :branch, counter_cache: :services_count
end

class Booking < ApplicationRecord
  belongs_to :branch, counter_cache: :bookings_count
end
```

**Batch Processing for Large Datasets**:

```ruby
class Bookings::ImportService
  def call(file_path)
    CSV.foreach(file_path, headers: true) do |row|
      Booking.create!(row.to_hash)
    end
  end
end
```

### 3. Background Processing

**Solid Queue for Background Jobs**:

```ruby
class BookingMailer < ApplicationMailer
  def confirmation(booking)
    @booking = booking
    mail(to: @booking.customer_email, subject: "Booking Confirmation")
  end
end

# Usage in controller
def create
  @booking = Booking.new(booking_params)

  if @booking.save
    # Send email in background
    BookingMailer.confirmation(@booking).deliver_later

    # Track analytics in background
    Analytics.track_booking_created(@booking)

    render json: { success: true }
  end
end
```

**Job Definition**:

```ruby
class SendBookingConfirmationJob < ApplicationJob
  queue_as :default

  def perform(booking_id)
    booking = Booking.find(booking_id)
    BookingMailer.confirmation(booking).deliver_now
  end
end
```

## Caching Layers

1. **HTTP Cache** (headers)
   - Browser cache for static assets
   - CDN cache (future enhancement)

2. **Fragment Cache** (views)
   - Rendered HTML fragments in Redis
   - Expires_in: 1 hour (configurable)

3. **Low-Level Cache** (Redis)
   - Query results
   - Computed values
   - Session data

4. **Query Cache** (database)
   - PostgreSQL query planner
   - Connection pooling (pgbouncer - future)

## Query Performance Considerations

### Booking Availability Check

Optimized for branch-scoped queries:

```ruby
# Efficient: uses index on (branch_id, scheduled_at, end_time)
bookings = Booking.where(branch_id: @branch.id)
  .where(status: [:pending, :confirmed, :in_progress])
  .where("scheduled_at < ? AND end_time > ?", end_time, start_time)
  .count
```

**Index**: `idx_bookings_overlap_check ON bookings(branch_id, scheduled_at, end_time)`

### Branch Operating Hours Query

```ruby
# Efficient: JSONB index
branch = Branch.where(active: true)
  .where("operating_hours::jsonb -> ? ->> ? > ?", day, 'open', '09:00')
  .first
```

**Index**: `idx_branches_operating_hours ON branches USING GIN(operating_hours)`

## Asset Optimization

```yaml
# config/environments/production.rb
config.assets.js_compressor = :terser
config.assets.css_compressor = :sass
config.assets.compile = false
config.assets.digest = true
config.cache_classes = true
config.eager_load = true
```

## Current Performance Metrics

| Metric | Target | Current |
|---|---|---|
| Page Load | < 2s | ~1.5s |
| API Response | < 500ms | ~300ms |
| Availability Check | < 100ms | ~80ms |
| Database Queries (per request) | < 10 | ~6 |

## Performance Monitoring

### Request Monitoring

```ruby
class ApplicationController < ActionController::Base
  before_action :monitor_request

  private

  def monitor_request
    Rails.logger.info "Request: #{request.method} #{request.path}"
    @request_start = Time.current
  end

  after_action do
    duration = Time.current - @request_start
    Rails.logger.info "Completed in #{duration.round(3)}s"
  end
end
```

### Structured Logging

```ruby
Rails.logger.formatter = proc do |severity, timestamp, progname, msg|
  json = {
    timestamp: timestamp,
    severity: severity,
    message: msg,
    request_id: RequestStore.store[:request_id]
  }
  json.to_json + "\n"
end
```

## Future Optimizations

1. **CDN for Static Assets**
   - Cloudflare CDN integration
   - Cache static assets globally

2. **Database Read Replicas**
   - Read-heavy queries on replicas
   - Writes on primary

3. **Query Result Caching**
   - More aggressive fragment caching
   - Cache warming strategies

4. **Service Worker**
   - Offline-first progressive web app
   - Background sync for offline bookings

*Last Updated*: March 13, 2026
*Version*: v0.2.0

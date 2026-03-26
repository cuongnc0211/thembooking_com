# Deployment & Infrastructure Architecture

## Technology Stack

### Backend
- **Ruby**: 3.3.0 (managed by asdf)
- **Rails**: 8.0.0 with Solid gems
- **Database**: PostgreSQL 14+
- **Cache**: Redis 6+
- **Jobs**: Solid Queue
- **WebSockets**: Solid Cable

### Frontend
- **Rendering**: Rails Server-Side Rendering
- **Framework**: Hotwire (Turbo + Stimulus)
- **Styling**: Tailwind CSS
- **JavaScript**: Selective React for complex components

### Infrastructure
- **Deployment**: Kamal (Docker orchestration)
- **Containerization**: Docker with Alpine base
- **Hosting**: Self-hosted on PC infrastructure
- **Tunneling**: Cloudflare Tunnel for secure access
- **SSL/TLS**: Let's Encrypt via Kamal

## Docker Deployment

### Dockerfile Configuration

```dockerfile
# Multi-stage build for production
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

**Image Size**: ~500MB (Alpine base + Rails + dependencies)

## Kamal Deployment Configuration

### Main Configuration (config/kamal.yml)

```yaml
service: thembooking
image: thembooking

servers:
  web:
    - "mypc.cuongnguyenfu.com"

registry:
  username: <%= ENV["REGISTRY_USERNAME"] %>
  password: <%= ENV["REGISTRY_PASSWORD"] %>
  server: docker.io

env:
  RAILS_ENV: production
  DATABASE_URL: postgres://user:pass@localhost/thembooking_production
  REDIS_URL: redis://localhost:6379/0
  SECRET_KEY_BASE: <%= ENV["SECRET_KEY_BASE"] %>

volumes:
  - /data/thembooking/storage:/app/storage
  - /data/thembooking/db:/var/lib/postgresql

# Health check
healthcheck:
  cmd: "curl -f http://localhost:3000/up || exit 1"
  interval: 30s
  timeout: 10s
  retries: 3

# Hooks for automated deployment
hooks:
  build:
    - bundle install
    - rails assets:precompile
  deploy:
    - rails db:migrate
    - rails db:seed

# Zero-downtime deployment
boot:
  limit: 30
  wait: 5
```

### Deployment Commands

```bash
# Deploy application
kamal deploy

# Check deployment status
kamal app details

# View logs in real-time
kamal app logs -f

# Rollback to previous version
kamal app rollback

# SSH into server
kamal app exec bash

# Run Rails command on production
kamal app exec rails console
```

## Database Setup

### PostgreSQL Configuration

```bash
# Create production database
createdb thembooking_production

# Create user with privileges
createuser thembooking_user
psql -c "ALTER USER thembooking_user WITH PASSWORD 'secure_password';"
psql -c "GRANT ALL PRIVILEGES ON DATABASE thembooking_production TO thembooking_user;"
```

### Database Backups

```bash
# Daily backup script
#!/bin/bash
BACKUP_DIR="/backups/thembooking"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

pg_dump -U thembooking_user thembooking_production | gzip > $BACKUP_DIR/backup_$TIMESTAMP.sql.gz

# Keep only last 30 days
find $BACKUP_DIR -name "backup_*.sql.gz" -mtime +30 -delete
```

### Connection Pooling (PgBouncer - Future)

```ini
[databases]
thembooking_production = host=localhost port=5432 user=thembooking_user password=xxx dbname=thembooking_production

[pgbouncer]
pool_mode = transaction
max_client_conn = 1000
default_pool_size = 25
```

## Redis Configuration

### Local Redis Setup

```bash
# Install Redis
brew install redis  # macOS
apt install redis-server  # Ubuntu

# Start Redis daemon
redis-server

# Test connection
redis-cli ping
# Output: PONG
```

### Redis Configuration (redis.conf)

```conf
port 6379
bind 127.0.0.1
daemonize yes
pidfile /var/run/redis.pid
logfile "/var/log/redis/redis-server.log"
maxmemory 2gb
maxmemory-policy allkeys-lru
```

## Cloudflare Tunnel Configuration

### Tunnel Setup

```bash
# Install cloudflared
curl -L --output cloudflared.tgz https://github.com/cloudflare/cloudflared/releases/download/2024.1.0/cloudflared-linux-amd64.tgz

# Authenticate with Cloudflare
cloudflared tunnel login

# Create tunnel
cloudflared tunnel create thembooking

# Configure tunnel (tunnel config)
tunnel: <UUID>
credentials-file: /root/.cloudflare-warp/<UUID>.json

ingress:
  - hostname: thembooking.com
    service: http://localhost:3000
  - hostname: www.thembooking.com
    service: http://localhost:3000
  - service: http_status:404
```

### Run Tunnel

```bash
cloudflared tunnel run thembooking
```

## Monitoring & Health Checks

### Health Check Endpoint

```ruby
class HealthController < ApplicationController
  skip_authentication

  def show
    # Database connectivity check
    ActiveRecord::Base.connection.execute('SELECT 1')

    # Redis connectivity check
    Redis.new.ping

    render json: {
      status: 'healthy',
      timestamp: Time.current,
      database: 'connected',
      cache: 'connected',
      version: Rails.application.config.version
    }
  end
end
```

**Route**: `GET /up` (used by Kamal healthcheck)

### Monitoring Stack (Future)

| Tool | Purpose | Status |
|---|---|---|
| New Relic | APM (Application Performance Monitoring) | Planned |
| Sentry | Error tracking and reporting | Planned |
| DataDog | Infrastructure monitoring | Planned |
| LogRocket | User session replay | Planned |

## Scaling Considerations

### Current State
- Single server deployment
- Monolithic Rails application
- Single PostgreSQL instance
- Single Redis instance

### Near-Term Scaling (Next 6 months)

```yaml
Application:
  Multiple app instances with load balancer
  Horizontal scaling capability ready
  Stateless session management

Database:
  Read replicas for reporting queries
  Connection pooling with PgBouncer
  Regular backup strategy

Cache:
  Redis Sentinel for high availability
  Cluster mode for horizontal scaling
```

### Long-Term Scaling (6+ months)

```yaml
Microservices:
  Separate booking service
  Separate notification service
  API gateway for routing

Database:
  Sharding by business_id
  Table partitioning for large datasets
  Multi-region replication

Cache:
  Distributed cache clusters
  Cache-aside pattern implementation
  Cache warming for popular content
```

## Deployment Checklist

- [ ] Docker image builds successfully
- [ ] Environment variables configured
- [ ] Database migrations run
- [ ] Assets precompiled
- [ ] SSL certificate valid
- [ ] Health check endpoint responds
- [ ] Logs accessible
- [ ] Backups configured
- [ ] Rollback procedure tested
- [ ] Monitoring tools connected

## Maintenance Windows

- **Regular Updates**: First Sunday of month, 2-3 AM UTC
- **Emergency Patches**: ASAP, out-of-band
- **Database Maintenance**: Second Sunday of month, 3-4 AM UTC

## Disaster Recovery

**RTO (Recovery Time Objective)**: < 1 hour
**RPO (Recovery Point Objective)**: < 1 day

```bash
# Restore from backup
gunzip -c /backups/thembooking/backup_20260301_020000.sql.gz | psql -U thembooking_user thembooking_production

# Restart application
kamal deploy
```

*Last Updated*: March 13, 2026
*Version*: v0.2.0

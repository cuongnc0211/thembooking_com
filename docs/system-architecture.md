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

### Phase 1 Changes (Multi-Location Support)

The architecture has been updated to support multiple business locations:

- **Business**: Now a brand entity only (name, type, description, logo)
- **Branch**: Physical location with slug, address, phone, operating_hours, capacity
- **Services, Bookings, BusinessClosures**: All now belong to Branch instead of Business

This enables:
- Multiple locations per business
- Branch-scoped availability checking
- Branch-specific operating hours and closures
- Public booking URL: `/branch-slug` (branch-level, not business-level)

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

*Last Updated*: March 13, 2026
*Version*: v0.2.0 (Modular Structure)

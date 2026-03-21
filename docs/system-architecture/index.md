# ThemBooking System Architecture

ThemBooking uses a modern Rails 8 architecture designed for simplicity, maintainability, and scalability.

## Architecture Overview

The system follows a layered architecture with clear separation of concerns:
- **Presentation Layer**: ERB views, Hotwire, and React components
- **Business Logic Layer**: Service objects, models, and domain entities
- **Data Access Layer**: PostgreSQL database and Redis cache

### Key Architectural Change (Phase 1)

Business is now a **brand entity only**. Location-specific data moved to Branch model:
- **Business**: Brand information only (name, type, description, logo)
- **Branch**: Physical location (slug, address, phone, operating_hours, capacity)
- **Services, Bookings, BusinessClosures**: All now belong to Branch

This enables multi-location support while maintaining data isolation per branch.

## Contents

- [Data Architecture](./data-architecture.md) - Database schema, relationships, and optimization
- [Application Architecture](./application-architecture.md) - Controllers, services, and domain models
- [Security Architecture](./security-architecture.md) - Authentication, authorization, and data protection
- [Performance Architecture](./performance-architecture.md) - Caching, query optimization, and background jobs
- [Deployment & Infrastructure](./deployment-infrastructure.md) - Docker, Kamal, and deployment strategy

## Technical Stack

**Backend**: Rails 8.0.0, Ruby 3.3.0, PostgreSQL 14+, Redis 6+
**Frontend**: Rails SSR, Hotwire (Turbo + Stimulus), Tailwind CSS, selective React
**Deployment**: Kamal with Docker, self-hosted on PC infrastructure with Cloudflare Tunnel

## Key Principles

1. **Modularity**: Clean separation of concerns with bounded contexts
2. **Simplicity**: Rails conventions and minimal abstractions
3. **Security**: Defense in depth with multiple security layers
4. **Performance**: Database optimization and caching strategies
5. **Scalability**: Stateless services with horizontal scaling capability

*Last Updated*: March 13, 2026 (Phase 1 Multi-Location)
*Version*: v0.2.0

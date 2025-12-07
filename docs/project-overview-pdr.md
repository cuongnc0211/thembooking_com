# ThemBooking - Project Overview & Product Development Requirements (PDR)

## Executive Summary

**Project Name**: ThemBooking (thembooking.com)
**Current Version**: v0.1.2 - Onboarding System Complete
**Target Market**: Vietnamese service-based businesses (barbershops, salons, spas, nail salons)
**Value Proposition**: Affordable booking and appointment management platform (99k-299k VND/month)

## Project Vision

ThemBooking aims to become the leading booking and appointment management platform for service-based businesses in Vietnam. We provide professional booking tools at affordable pricing, targeting local businesses that need modern scheduling capabilities without the premium costs of international solutions like Fresha or Square Appointments.

## Market Analysis

### Target Customers
1. **Primary**: Small to medium service businesses (1-10 employees)
   - Barber shops and hair salons
   - Spas and massage parlors
   - Nail salons and beauty clinics
   - Small aesthetic centers

2. **Secondary**: Independent service providers
   - Freelance beauticians
   - Independent massage therapists
   - Mobile service providers

### Market Pain Points
1. **Scheduling Chaos**
   - No-show rates of 20-30%
   - Double bookings and scheduling conflicts
   - Manual tracking using paper notebooks or memory

2. **Online Presence Gap**
   - 70% of Vietnamese small businesses lack professional online booking
   - Heavy reliance on Zalo messaging for appointments
   - No centralized booking management

3. **Capacity Management Issues**
   - Difficulty managing walk-in customers
   - Overbooking due to poor visibility
   - No real-time queue management

4. **Cost Barriers**
   - Fresha/Square Appointments pricing ($30-100/month) too high for Vietnamese market
   - Complex setup requirements
   - Payment processing challenges

## Product Overview

### Core Features

#### ✅ Completed Features (v0.1.2)
1. **User Authentication System**
   - Email/password authentication
   - Email verification flow
   - Password reset functionality
   - Secure session management

2. **Onboarding System (Phase 1-4 Complete)**
   - 4-step progressive onboarding flow
   - User profile setup (name, phone, avatar)
   - Business profile creation (name, address, capacity)
   - Operating hours configuration
   - Service management with pricing
   - Automatic progress tracking and resume capabilities

3. **Database Architecture**
   - PostgreSQL with proper relationships
   - User → Business → Services hierarchy
   - Booking system foundation (ready for implementation)
   - Supporting models for staff, resources, customers

4. **Security & Access Control**
   - Multi-layer authentication
   - Onboarding completion enforcement
   - Role-based access control
   - Email verification requirements

#### 🚧 In Progress Features
- Service management CRUD interface
- Operating hours configuration UI
- Business profile management

#### 📋 Planned MVP Features (v1.0)
1. **Online Booking Flow**
   - Public booking pages (thembooking.com/business-slug)
   - Service selection with pricing
   - Time slot availability checking
   - Customer information collection
   - Booking confirmations (email/SMS)

2. **Walk-in Management**
   - Real-time queue tracking
   - Quick add walk-in functionality
   - Wait time estimation
   - Position tracking for customers

3. **Daily Operations Dashboard**
   - Today's appointments view
   - Real-time capacity monitoring
   - Booking status management (confirm, start, complete, cancel)
   - No-show tracking

4. **Business Landing Page**
   - Customizable business profile page
   - Service showcase with pricing
   - Operating hours display
   - Contact information
   - Basic theme options

5. **Notification System**
   - Booking confirmations
   - Appointment reminders
   - Real-time dashboard updates
   - Email integration (SendGrid)

#### 📋 Post-MVP Features (v1.1 - v2.0)
1. **Staff Management (v1.1)**
   - Multiple employee profiles
   - Individual availability settings
   - Staff assignment to bookings
   - Performance tracking

2. **Customer Accounts (v1.2)**
   - Repeat customer profiles
   - Booking history
   - Customer notes and preferences
   - Loyalty program foundation

3. **Advanced Notifications (v1.3)**
   - SMS/Zalo integration
   - Two-way messaging
   - Automated reminders
   - Cancellation notifications

4. **Analytics Dashboard (v1.4)**
   - Revenue tracking
   - Customer analytics
   - Service popularity metrics
   - No-show rate analysis
   - Peak hour identification

5. **Multi-location Support (v2.0)**
   - Multiple business locations
   - Centralized management
   - Location-specific booking pages
   - Cross-location staff scheduling

6. **Mobile Application (v2.0)**
   - Hotwire Native wrapper
   - iOS and Android apps
   - Real-time notifications
   - Offline capabilities

## Technical Architecture

### Backend Stack
- **Ruby on Rails 8**: Latest Rails with modern defaults
- **PostgreSQL**: Primary database
- **Redis**: Session storage and caching (Solid Cache)
- **Solid Queue**: Background job processing
- **Solid Cable**: WebSocket connections for real-time features

### Frontend Stack
- **Rails SSR Views**: Server-rendered HTML
- **Hotwire (Turbo + Stimulus)**: Primary interaction layer
- **React**: Selective use for complex components (calendar, availability editor)
- **Tailwind CSS**: Utility-first styling framework

### Infrastructure
- **Kamal**: Docker-based deployment
- **Docker**: Containerization
- **Cloudflare Tunnel**: Secure external connectivity
- **Self-hosted**: Cost-effective server on local infrastructure

### Development Practices
- **TDD (Test-Driven Development)**: All new features follow RSpec workflow
- **RSpec**: Testing framework with FactoryBot and Faker
- **Code Review**: Mandatory review process for all changes
- **CI/CD**: Automated testing and deployment pipeline

## Business Model

### Pricing Strategy (Vietnamese Market)
| Tier | Price (VND) | Features | Target |
|------|-------------|----------|---------|
| **Starter** | 99k/month | Basic booking, 1 business, 100 bookings/month | Micro businesses |
| **Professional** | 199k/month | Advanced features, 500 bookings/month, analytics | Small businesses |
| **Business** | 299k/month | Unlimited bookings, multi-location, staff management | Medium businesses |

### Revenue Streams
1. **Subscription Model**: Monthly recurring revenue
2. **Transaction Fees**: 1-2% on payments processed
3. **Premium Features**: Additional services (SMS, advanced analytics)
4. **Enterprise**: Custom pricing for larger chains

### Go-to-Market Strategy
1. **Direct Sales**: Target specific business districts
2. **Digital Marketing**: Facebook/Google ads targeting business owners
3. **Partnerships**: Beauty supply stores, cosmetology schools
4. **Referral Program**: Customer acquisition incentives

## Competitive Analysis

### Competitive Advantages
1. **Pricing**: 70-80% cheaper than Fresha/Square
2. **Local Focus**: Vietnamese language, local payment methods (Sepay)
3. **Simplicity**: Easier setup and use than complex international solutions
4. **Real-time Features**: Unique queue management capabilities

### Key Differentiators
1. **Queue Management**: Real-time walk-in tracking (competitive advantage)
2. **Mobile-First**: Built for Vietnamese mobile usage patterns
3. **Payment Integration**: Local payment processing (Sepay integration)
4. **Offline Capability**: Works without constant internet connection

## Development Roadmap

### Phase 1: Foundation (✅ Complete)
- User authentication system
- Database architecture
- Basic onboarding flow
- Business profile creation

### Phase 2: Core Features (🚧 In Progress)
- Service management
- Operating hours configuration
- Business profile management

### Phase 3: MVP Launch (📋 Q1 2025)
- Online booking flow
- Walk-in management
- Daily operations dashboard
- Business landing page
- Email notifications

### Phase 4: Market Validation (📋 Q2 2025)
- User feedback collection
- Feature refinement
- Performance optimization
- Marketing campaign launch

### Phase 5: Growth Features (📋 Q3-Q4 2025)
- Staff management
- Customer accounts
- Advanced notifications
- Analytics dashboard

### Phase 6: Enterprise Scale (📋 2026)
- Multi-location support
- Mobile application
- API for third-party integrations
- Advanced security features

## Success Metrics

### User Acquisition Targets
- **Month 1**: 10 paying customers
- **Month 3**: 50 paying customers
- **Month 6**: 200 paying customers
- **Month 12**: 500 paying customers

### Engagement Metrics
- **Onboarding Completion**: >80%
- **Active Businesses**: >70% monthly active
- **Bookings Per Business**: >50/month (post-MVP)
- **Customer Retention**: >80% quarterly

### Business Metrics
- **Monthly Recurring Revenue (MRR)**:
  - Month 1: 1,000,000 VND
  - Month 6: 10,000,000 VND
  - Month 12: 25,000,000 VND
- **Customer Acquisition Cost (CAC)**: <500,000 VND
- **Lifetime Value (LTV)**: >1,000,000 VND
- **Gross Margin**: >70%

## Risk Assessment

### Technical Risks
1. **Performance**: PostgreSQL scaling with high booking volume
2. **Real-time Features**: WebSocket reliability and performance
3. **Payment Integration**: Sepay API stability and compliance
4. **Mobile App**: Hotwire Native limitations and device compatibility

### Business Risks
1. **Market Adoption**: Slow uptake among traditional businesses
2. **Pricing Sensitivity**: Price resistance in target market
3. **Competition**: International players entering Vietnam market
4. **Regulatory**: Payment processing regulations and compliance

### Mitigation Strategies
1. **Technical**: Load testing, caching strategies, fallback systems
2. **Business**: Freemium model, local partnerships, flexible pricing
3. **Competitive**: Feature differentiation, superior customer support
4. **Regulatory**: Legal compliance team, regulatory monitoring

## Team & Resources

### Current Team
- **Lead Developer**: Cuong Nguyen (Full-stack development)
- **UI/UX Design**: External contractor (as needed)
- **Business Strategy**: Cuong Nguyen (market research and customer development)

### Required Resources
1. **Development**: Additional Rails/React developers for acceleration
2. **Marketing**: Digital marketing specialist for customer acquisition
3. **Support**: Customer success manager for business relationships
4. **Infrastructure**: Cloud hosting scaling plan

## Conclusion

ThemBooking addresses a significant market gap in Vietnam's service industry by providing affordable, professional booking tools tailored to local business needs. With a solid technical foundation, clear product roadmap, and focused market strategy, the project is positioned for successful launch and growth.

The onboarding system completion represents a critical milestone, enabling smooth user onboarding and establishing the foundation for core booking functionality. Subsequent development will focus on delivering immediate value through the MVP features while planning for future expansion based on market feedback and user needs.

---

*Last Updated*: December 7, 2025
*Version*: v0.1.2 - Onboarding System Complete
*Next Milestone*: v1.0 MVP - Online Booking Flow
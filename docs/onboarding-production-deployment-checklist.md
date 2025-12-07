# Onboarding System Production Deployment Checklist

## Overview

This checklist provides a comprehensive validation process for deploying the ThemBooking onboarding system to production. Each item must be verified before deployment to ensure system reliability, security, and performance.

---

## Phase 1: Pre-Deployment Validation

### 1.1 Code Quality Verification

#### Test Suite Requirements
- [ ] **All tests pass**: `bundle exec rspec` returns 0 failures
- [ ] **Test coverage meets standards**: 95/95 tests passing
- [ ] **No skipped tests**: All tests are actively maintained
- [ ] **Test data consistency**: Factories generate valid test data
- [ ] **Performance benchmarks**: Test execution < 30 seconds

#### Code Quality Checks
```bash
# Run full test suite
bundle exec rspec

# Check specific test categories
bundle exec rspec spec/system/
bundle exec rspec spec/models/
bundle exec rspec spec/requests/
bundle exec rspec spec/helpers/

# Verify no tests are skipped
bundle exec rspec --format documentation
```

### 1.2 Security Validation

#### Input Sanitization
- [ ] **HTML escaping**: All dynamic content properly escaped with `h()` helper
- [ ] **Form validation**: Client and server-side validation implemented
- [ ] **File upload security**: Avatar uploads properly restricted
- [ ] **CSRF protection**: All forms include Rails CSRF tokens
- [ ] **SQL injection prevention**: Proper parameterized queries

#### Authentication & Authorization
- [ ] **Authentication flow**: Email confirmation enforced
- [ ] **Authorization checks**: Users can only access their data
- [ ] **Session management**: Proper session lifecycle
- [ ] **Password security**: Strong password requirements enforced
- [ ] **Access control**: Onboarding completion verified before dashboard access

### 1.3 Database Schema Verification

#### Migration Validation
- [ ] **Latest migrations**: All pending migrations applied
- [ ] **Schema consistency**: Database matches schema.rb
- [ ] **Data integrity**: All constraints properly defined
- [ ] **Index optimization**: Appropriate indexes for performance
- [ ] **Backup verification**: Recent database backup available

#### Data Validation
```sql
-- Check onboarding step distribution
SELECT onboarding_step, COUNT(*)
FROM users
GROUP BY onboarding_step;

-- Verify business data integrity
SELECT b.name, u.email, COUNT(s.id) as service_count
FROM businesses b
JOIN users u ON b.user_id = u.id
LEFT JOIN services s ON b.id = s.business_id
GROUP BY b.id, u.email;

-- Check operating hours structure
SELECT name, operating_hours
FROM businesses
WHERE operating_hours IS NOT NULL;
```

---

## Phase 2: Environment Preparation

### 2.1 Production Environment Setup

#### Server Configuration
- [ ] **Ruby version**: 3.3.0 installed and verified
- [ ] **Node.js version**: 20.x installed and verified
- [ ] **Database**: PostgreSQL 14+ running and accessible
- [ ] **Redis**: Redis 6+ running for caching
- [ ] **Environment variables**: All required variables set
- [ ] **File permissions**: Proper permissions for file uploads

#### Environment Variables
```bash
# Verify required environment variables
echo $DATABASE_URL
echo $REDIS_URL
echo $SECRET_KEY_BASE
echo $EMAIL_DOMAIN
```

### 2.2 Asset Compilation

#### Frontend Assets
- [ ] **CSS compilation**: Tailwind CSS compiled successfully
- [ ] **JavaScript compilation**: Stimulus controllers bundled
- [ ] **Asset fingerprinting**: Assets have proper digests
- [ ] **Precompilation**: No errors during asset compilation
- [ ] **Cache busting**: Proper cache-busting strategies

```bash
# Compile assets
rails assets:precompile RAILS_ENV=production

# Verify compiled assets
ls -la public/assets/
```

---

## Phase 3: Testing & Validation

### 3.1 Functional Testing

#### Complete User Journey
- [ ] **Registration flow**: User can register and confirm email
- [ ] **Onboarding completion**: All 5 steps complete successfully
- [ ] **Dashboard access**: Redirect to onboarding if incomplete
- [ ] **Navigation**: Can navigate between completed steps
- [ ] **Error handling**: Graceful handling of invalid inputs

#### Edge Case Testing
- [ ] **Concurrent access**: Multiple users onboarding simultaneously
- [ ] **Network interruptions**: Graceful handling of failed requests
- [ ] **Browser compatibility**: Works in Chrome, Firefox, Safari
- [ ] **Mobile devices**: Responsive design tested
- [ ] **Large data**: Handles multiple services and complex hours

### 3.2 Performance Testing

#### Load Testing
- [ ] **Response time**: Pages load < 2 seconds
- [ ] **Database queries**: No N+1 queries identified
- [ ] **Memory usage**: Appropriate memory consumption
- [ ] **Database connections**: Proper connection pooling
- [ ] **Caching**: Cache hits/misses within acceptable ranges

#### Performance Commands
```bash
# Check Rails performance
rails log:tail

# Monitor database queries
rails dbconsole -p

# Check asset loading
curl -I https://thembooking.com/assets/application-*.js
curl -I https://thembooking.com/assets/application-*.css
```

### 3.3 Security Testing

#### Vulnerability Scanning
- [ ] **XSS protection**: Verify all user input is escaped
- [ ] **SQL injection**: Test with malicious input
- [ ] **CSRF verification**: Forms include proper tokens
- [ ] **Authentication bypass**: No unauthorized access
- [ ] **Session hijacking**: Secure session management

#### Security Commands
```bash
# Check for common vulnerabilities
bundle exec brakeman

# Verify Rails security configuration
rails runner 'puts Rails.application.config.action_controller.permitted_parameters'

# Check file upload security
ls -la storage/
```

---

## Phase 4: Deployment Preparation

### 4.1 Backup Procedures

#### Database Backup
- [ ] **Full database backup**: Complete database exported
- [ ] **Backup verification**: Backup can be restored
- [ ] **Backup location**: Secure storage location confirmed
- [ ] **Backup encryption**: Sensitive data encrypted
- [ ] **Backup frequency**: Automated backup schedule tested

```bash
# Create database backup
pg_dump $DATABASE_URL > backup_$(date +%Y%m%d_%H%M%S).sql

# Verify backup
head -5 backup_$(date +%Y%m%d_%H%M%S).sql
```

#### File Backup
- [ ] **Upload directory**: Avatar files backed up
- [ ] **Configuration files**: All configs backed up
- [ ] **SSL certificates**: Certificates backed up
- [ ] **Log files**: Recent logs archived

### 4.2 Rollback Plan

#### Rollback Strategy
- [ ] **Rollback script**: Automated rollback script ready
- [ ] **Database rollback**: Migration rollback plan tested
- [ ] **Asset rollback**: Previous assets preserved
- [ ] **Data migration**: Data migration rollback plan
- [ ] **Communication**: Rollback notification process defined

#### Rollback Commands
```bash
# Example rollback commands
kamal app rollback
rails db:rollback
git checkout main
```

### 4.3 Monitoring Setup

#### Application Monitoring
- [ ] **Health checks**: Health endpoints implemented
- [ ] **Error tracking**: Error tracking service configured
- [ ] **Performance monitoring**: Performance metrics configured
- [ ] **Log aggregation**: Logs centralized and searchable
- [ ] **Alert system**: Alerts configured for critical issues

#### Monitoring Commands
```bash
# Check application health
curl https://thembooking.com/health

# Monitor Rails logs
rails log:tail

# Check system resources
top
df -h
```

---

## Phase 5: Deployment Execution

### 5.1 Final Pre-Deployment Checks

#### System Status
- [ ] **All services running**: Web server, database, Redis running
- [ ] **Disk space**: Sufficient disk space available
- [ ] **Network connectivity**: All services accessible
- [ [ ] **SSL certificates**: Valid certificates installed
- [ ] **DNS propagation**: DNS changes propagated

#### Final Verification
```bash
# Check system status
systemctl status nginx
systemctl status postgresql
systemctl status redis

# Check application status
curl -f https://thembooking.com/health
curl -f https://thembooking.com/users/sign_in

# Check database connectivity
rails runner 'puts User.count'
```

### 5.2 Deployment Steps

#### Step-by-Step Deployment
1. [ ] **Stop application**: Graceful shutdown of current version
2. [ ] **Pull latest code**: Update to latest commit
3. [ ] **Install dependencies**: `bundle install`
4. [ ] **Run migrations**: `rails db:migrate`
5. [ ] **Precompile assets**: `rails assets:precompile`
6. [ ] **Start application**: Start new version
7. [ ] **Verify deployment**: All endpoints responding

```bash
# Deployment commands
kamal deploy

# Post-deployment verification
rails runner 'puts "Deployment successful"'
rails runner 'puts User.count'
rails runner 'puts Business.count'
```

---

## Phase 6: Post-Deployment Validation

### 6.1 Immediate Verification

#### System Health
- [ ] **Application status**: All endpoints returning 200
- [ ] **Database connectivity**: Database queries successful
- [ ] **User registration**: New user signup working
- [ ] **Email delivery**: Confirmation emails sending
- [ ] **File uploads**: Avatar uploads working

#### User Journey Validation
- [ ] **New user onboarding**: Complete flow tested
- [ ] **Dashboard access**: Proper redirects working
- [ ] **Data persistence**: All data saved correctly
- [ ] **Error messages**: User-friendly errors displayed
- [ ] **Navigation**: All navigation working correctly

### 6.2 Performance Monitoring

#### Performance Metrics
- [ ] **Response times**: Monitoring response times
- [ ] **Database performance**: Query performance monitored
- [ ] **Error rates**: Error rate monitoring
- [ ] **Resource usage**: CPU, memory, disk usage
- [ ] **User satisfaction**: User feedback collection

#### Monitoring Commands
```bash
# Monitor application performance
rails runner 'puts Rails.cache.stats'

# Check database performance
rails runner 'puts User.connection.execute("SELECT * FROM pg_stat_activity").to_a'

# Monitor error rates
tail -f log/production.log | grep ERROR
```

### 6.3 Security Validation

#### Security Checks
- [ ] **Log monitoring**: Security logs reviewed
- [ ] **Failed logins**: Failed login attempts monitored
- [ ] **File access**: Unauthorized file access attempts
- [ ] **Database queries**: Suspicious queries logged
- [ ] **Session security**: Session hijacking attempts logged

---

## Phase 7: Ongoing Maintenance

### 7.1 Daily Tasks

#### Routine Monitoring
- [ ] **Application health**: Health checks performed
- [ ] **Error monitoring**: Errors reviewed and resolved
- [ ] **Performance review**: Performance metrics analyzed
- [ [ ] **Security updates**: Security patches applied
- [ ] **Backup verification**: Backups tested

#### Daily Commands
```bash
# Daily health check
curl -f https://thembooking.com/health

# Check for errors
tail -f log/production.log | grep ERROR

# Monitor performance
rails runner 'puts "Memory usage: #{`ps -o rss= -p #{Process.pid}`.to_i / 1024} MB"'
```

### 7.2 Weekly Tasks

#### Maintenance Activities
- [ ] **Database optimization**: Database queries optimized
- [ ] **Cache clearing**: Cache cleared and refreshed
- [ ] **Log rotation**: Logs rotated and archived
- [ ] **Security audit**: Security audit performed
- [ ] **Performance review**: Weekly performance review

#### Weekly Commands
```bash
# Database optimization
rails db:analyze

# Cache management
rails runner 'Rails.cache.clear'

# Log rotation
logrotate -f /etc/logrotate.d/rails
```

### 7.3 Monthly Tasks

#### Long-term Maintenance
- [ ] **Security patches**: Latest security patches applied
- [ ] **Database cleanup**: Old data archived or deleted
- [ ] **Performance tuning**: Performance tuning performed
- [ ] **Documentation update**: Documentation reviewed and updated
- [ ] **Capacity planning**: Capacity planning for growth

---

## Emergency Procedures

### Critical Issues

#### Database Failure
1. **Immediate action**: Switch to read-only mode
2. **Recovery**: Restore from latest backup
3. **Communication**: Notify users of service interruption

#### Security Breach
1. **Immediate action**: Take application offline
2. **Investigation**: Identify breach source and scope
3. **Recovery**: Patch vulnerabilities and restore from backup
4. **Prevention**: Implement additional security measures

#### Performance Degradation
1. **Monitor**: Identify performance bottlenecks
2. **Scale**: Add resources if needed
3. **Optimize**: Optimize queries and code
4. **Communicate**: Keep users informed of issues

---

## Contact Information

### Technical Contacts
- **Lead Developer**: Cuong Nguyen
- **DevOps Contact**: [Contact Information]
- **Security Contact**: [Contact Information]

### Support Contacts
- **General Support**: [Support Email/Phone]
- **Emergency Contact**: [Emergency Contact]
- **Documentation**: [Documentation Link]

---

## Deployment Sign-off

### Pre-Deployment Checklist
- [ ] All tests passing (95/95)
- [ ] Security validation complete
- [ ] Performance testing complete
- [ ] Database backup verified
- [ ] Rollback plan tested
- [ ] Monitoring configured
- [ ] Documentation updated

### Deployment Team
- [ ] Lead Developer: _________________________
- [ ] DevOps Engineer: _________________________
- [ ] QA Engineer: ___________________________
- [ ] Project Manager: ________________________

### Deployment Approval
**I confirm that all deployment requirements have been met and the system is ready for production deployment.**

**Signature**: _________________________
**Date**: _________________________

---

*Last Updated*: December 7, 2025
*Version*: 1.0.0
*Status*: ✅ Active Checklist
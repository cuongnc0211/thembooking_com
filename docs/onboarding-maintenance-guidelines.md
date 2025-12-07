# Onboarding System Maintenance Guidelines

## Overview

This document provides comprehensive guidelines for maintaining and extending the ThemBooking onboarding system. These guidelines ensure continued system reliability, performance, and security as the system evolves.

---

## Maintenance Philosophy

### Core Principles

1. **Prevention Over Reaction**: Proactive maintenance prevents issues before they occur
2. **Documentation Driven**: All changes must be properly documented
3. **Test-First Development**: New features must follow TDD methodology
4. **User Impact Consideration**: Consider how changes affect user experience
5. **Performance Conscious**: Monitor and optimize performance continuously

### Maintenance Tiers

| Tier | Response Time | Impact Examples |
|------|---------------|-----------------|
| **Critical** | < 1 hour | System down, data loss, security breach |
| **High** | < 4 hours | Major functionality broken, poor performance |
| **Medium** | < 24 hours | Minor bugs, UI issues, non-critical features |
| **Low** | < 1 week | Documentation updates, minor improvements |

---

## Daily Maintenance Tasks

### 1. Health Monitoring

#### Application Health Checks
```bash
# Health check verification
curl -f https://thembooking.com/health || echo "Health check failed"

# Database connectivity
rails runner 'puts User.count' || echo "Database connection failed"

# Email delivery test
rails runner 'puts ActionMailer::Base.delivery_method' || echo "Email configuration issue"
```

#### Log Monitoring
```bash
# Check for errors in the last hour
tail -n 100 log/production.log | grep "$(date '+%Y-%m-%d %H').*ERROR" || echo "No errors in last hour"

# Monitor for slow queries (> 1 second)
grep -E ".*Completed .* in [0-9]+\.[0-9]{3}s.*" log/production.log | tail -10
```

### 2. Performance Monitoring

#### Key Metrics
- **Response Time**: Average < 2 seconds for all endpoints
- **Database Queries**: No N+1 queries identified
- **Memory Usage**: Application memory < 1GB
- **Error Rate**: < 0.1% error rate

#### Performance Commands
```bash
# Monitor Rails performance
rails log:tail

# Check memory usage
ps -o rss= -p $(pgrep -f puma) | awk '{print "Memory: " $1/1024 " MB"}'

# Check database connections
rails runner 'puts ActiveRecord::Base.connection_pool.checked_out.size'

# Monitor cache performance
rails runner 'puts Rails.cache.stats'
```

### 3. Security Monitoring

#### Security Checks
```bash
# Monitor for suspicious activity
grep -E ".*Failed login for.*" log/production.log | tail -5

# Check for SQL injection attempts
grep -E ".*SELECT.*FROM.*WHERE.*[\"';].*" log/production.log || echo "No SQL injection attempts"

# Monitor file upload security
ls -la storage/ | grep "^d" | wc -l | xargs -I {} echo "Directories in storage: {}"
```

---

## Weekly Maintenance Tasks

### 1. Database Maintenance

#### Database Optimization
```bash
# Analyze table statistics
rails db:analyze

# Rebuild indexes if needed
rails runner 'ActiveRecord::Base.connection.execute("REINDEX DATABASE thembooking_development")'

# Vacuum and analyze
rails runner 'ActiveRecord::Base.connection.execute("VACUUM ANALYZE")'
```

#### Query Optimization
```sql
-- Identify slow queries
SELECT query, mean_time, calls
FROM pg_stat_statements
ORDER BY mean_time DESC
LIMIT 10;

-- Check for missing indexes
SELECT schemaname, relname, indexrelname, idx_scan
FROM pg_stat_user_indexes
ORDER BY idx_scan ASC
LIMIT 10;
```

### 2. Code Quality Maintenance

#### Test Suite Maintenance
```bash
# Run all tests
bundle exec rspec

# Check test coverage
COVERAGE=true bundle exec rspec

# Update test data if needed
rails db:test:prepare
```

#### Code Quality Checks
```bash
# Check for code smells
bundle exec rubocop --rails

# Check for security issues
bundle exec brakeman

# Check for gem vulnerabilities
bundle exec bundle-audit check
```

### 3. Documentation Updates

#### Documentation Maintenance
- [ ] Update API documentation for any changes
- [ ] Review user guides for accuracy
- [ ] Update technical documentation
- [ ] Add comments for complex code
- [ ] Update deployment guides

#### Documentation Commands
```bash
# Generate documentation
yard doc

# Check for broken links
find docs -name "*.md" -exec grep -l "http" {} \; | xargs -I {} grep -H "http" {} | grep -E ".*\]\(http.*\).*" || echo "No links found"
```

---

## Monthly Maintenance Tasks

### 1. Security Updates

#### Security Patch Management
```bash
# Check for gem vulnerabilities
bundle exec bundle-audit update
bundle exec bundle-audit check

# Update Rails security patches
bundle update rails
bundle exec rails zeitwerk:check

# Verify all security configurations
rails runner 'puts Rails.application.config.filter_parameters'
```

#### Security Testing
```bash
# Run security tests
bundle exec rspec spec/requests/ --tag security

# Test authentication flows
rails runner 'puts User.where("email_confirmed_at IS NULL").count'

# Verify authorization
rails runner 'puts Business.count'
rails runner 'puts Service.count'
```

### 2. Performance Optimization

#### Performance Tuning
```sql
-- Add indexes for frequently queried columns
CREATE INDEX INDEX_NAME ON table_name (column_name);

-- Optimize queries for onboarding performance
EXPLAIN ANALYZE SELECT * FROM users WHERE onboarding_step = 1 LIMIT 100;

-- Monitor query performance
SELECT * FROM pg_stat_statements
ORDER BY mean_time DESC
LIMIT 20;
```

#### Caching Strategy
```ruby
# Implement caching for frequently accessed data
Rails.cache.fetch("user_onboarding_stats", expires_in: 1.hour) do
  User.group(:onboarding_step).count
end

# Clear cache when needed
Rails.cache.clear

# Monitor cache performance
Rails.cache.stats
```

### 3. Backup and Recovery

#### Backup Verification
```bash
# Verify database backup
pg_restore --list backup_$(date +%Y%m%d).sql

# Test file backup restoration
ls -la storage/backup/

# Verify backup integrity
rails runner 'puts BackupVerification.new.call'
```

#### Recovery Procedures
```bash
# Database recovery procedure
pg_dump $DATABASE_URL > recovery_test.sql
psql $DATABASE_URL < recovery_test.sql

# File restoration procedure
cp -r storage/backup/* storage/
```

---

## Quarterly Maintenance

### 1. System Architecture Review

#### Architecture Evaluation
- Review database schema for optimization opportunities
- Evaluate caching strategy effectiveness
- Assess performance bottlenecks
- Review security architecture
- Plan for scalability improvements

#### Architecture Commands
```sql
-- Review database growth
SELECT schemaname, relname, pg_size_pretty(pg_relation_size(C.oid)) AS size
FROM pg_class C
LEFT JOIN pg_namespace N ON N.oid = C.relnamespace
WHERE nspname NOT IN ('pg_catalog', 'information_schema')
ORDER BY pg_relation_size(C.oid) DESC
LIMIT 20;

-- Review table growth
SELECT schemaname, relname, n_tup_ins, n_tup_upd, n_tup_del
FROM pg_stat_user_tables
ORDER BY n_tup_ins DESC;
```

### 2. Technology Stack Updates

#### Version Updates
```bash
# Update Ruby version
asdf install ruby 3.3.1
asdf local ruby 3.3.1

# Update Node.js version
asdf install nodejs 20.x
asdf local nodejs 20.x

# Update Rails version
gem update rails
rails app:update
```

#### Dependency Updates
```bash
# Update all gems
bundle update

# Check for compatibility issues
bundle exec rails runner 'puts "Rails version: #{Rails.version}"'
bundle exec rails runner 'puts "Ruby version: #{RUBY_VERSION}"'

# Test with new versions
bundle exec rspec
```

### 3. User Experience Review

#### UX Analytics
```ruby
# Analyze onboarding completion rates
User.group(:onboarding_step).count.each do |step, count|
  puts "Step #{step}: #{count} users"
end

# Analyze drop-off points
completion_rate = User.where(onboarding_step: 5).count.to_f / User.count * 100
puts "Completion rate: #{completion_rate.round(2)}%"

# Analyze time spent on each step
User.where("onboarding_completed_at IS NOT NULL").average("onboarding_completed_at - created_at").to_i
```

---

## Annual Maintenance

### 1. Long-term Planning

#### Strategic Review
- Review business goals and technical alignment
- Plan for major feature additions
- Evaluate technology stack evolution
- Review security posture
- Plan for scaling requirements

#### Planning Commands
```ruby
# Review system growth
User.count
Business.count
Service.count

# Review database size
ActiveRecord::Base.connection.execute("SELECT pg_size_pretty(pg_database_size(current_database()))").first['pg_size_pretty']

# Review performance trends
Rails.logger.info "Average response time: #{average_response_time}s"
```

### 2. Disaster Recovery Testing

#### Recovery Procedures
```bash
# Test full system recovery
1. Take production backup
2. Restore to staging environment
3. Verify all functionality
4. Document recovery time

# Test failover procedures
rails runner 'puts FailoverTest.new.call'
```

---

## Issue Management

### Bug Fix Workflow

#### Bug Classification
1. **Reproduce**: Identify steps to reproduce the issue
2. **Isolate**: Determine the root cause
3. **Fix**: Implement the solution
4. **Test**: Verify the fix works
5. **Document**: Document the fix

#### Bug Fix Template
```ruby
# Bug: [Brief description]
# Steps to reproduce:
# 1. [Step 1]
# 2. [Step 2]
# 3. [Step 3]

# Root cause: [Analysis]

# Fix: [Implementation]

# Test: [Verification steps]

# Documentation: [Related documentation updates]
```

### Feature Development Process

#### Feature Implementation
1. **Planning**: Define requirements and acceptance criteria
2. **Design**: Create technical design document
3. **Development**: Implement following TDD
4. **Testing**: Comprehensive testing
5. **Deployment**: Deploy to production
6. **Monitoring**: Monitor for issues

#### Feature Template
```markdown
# Feature: [Feature name]

## Requirements
- [Requirement 1]
- [Requirement 2]
- [Requirement 3]

## Acceptance Criteria
- [Criteria 1]
- [Criteria 2]
- [Criteria 3]

## Technical Design
[Technical implementation details]

## Testing Plan
[Test cases and scenarios]

## Deployment Plan
[Deployment steps and timeline]
```

---

## Performance Guidelines

### Optimization Strategies

#### Database Optimization
```sql
-- Add indexes for frequently queried columns
CREATE INDEX INDEX_NAME ON table_name (column_name);

-- Optimize queries
EXPLAIN ANALYZE SELECT * FROM users WHERE onboarding_step = 1;

-- Monitor query performance
SELECT query, calls, total_time
FROM pg_stat_statements
ORDER BY total_time DESC
LIMIT 10;
```

#### Application Optimization
```ruby
# Use caching for expensive operations
Rails.cache.fetch("expensive_operation", expires_in: 1.hour) do
  ExpensiveOperation.new.call
end

# Optimize ActiveRecord queries
# Before: User.where(onboarding_step: 1).each { |user| user.update(attribute: value) }
# After: User.where(onboarding_step: 1).update_all(attribute: value)

# Use batch processing
User.find_each(batch_size: 100) do |user|
  # Process user
end
```

### Memory Management

#### Memory Optimization
```ruby
# Monitor memory usage
def memory_usage
  `ps -o rss= -p #{Process.pid}`.to_i / 1024
end

# Optimize ActiveRecord
ActiveRecord::Base.connection.clear_query_cache

# Use efficient data structures
# Use sets for unique values
# Use arrays for ordered lists
```

---

## Security Guidelines

### Security Best Practices

#### Input Validation
```ruby
# Always validate user input
validates :name, presence: true, length: { minimum: 2, maximum: 50 }
validates :phone, format: { with: /\A0\d{9}\z/ }

# Sanitize output
<%= h(user.name) %>

# Use Rails strong parameters
def user_params
  params.require(:user).permit(:name, :phone, :email)
end
```

#### Authentication & Authorization
```ruby
# Always authenticate
before_action :authenticate_user!

# Check authorization
def authorize_business!
  return unless @business.user != current_user
  redirect_to root_path, alert: "Access denied"
end

# Use secure session management
session[:user_id] = user.id
```

### Vulnerability Prevention

#### Common Vulnerabilities
- **XSS**: Always escape user input
- **SQL Injection**: Use ActiveRecord or parameterized queries
- **CSRF**: Rails handles CSRF automatically
- **Authentication Bypass**: Always verify user identity
- **Directory Traversal**: Validate file paths

#### Security Commands
```bash
# Run security scanning
bundle exec brakeman

# Check for known vulnerabilities
bundle exec bundle-audit check

# Test authentication
curl -I https://thembooking.com/users/sign_in
```

---

## Monitoring and Alerting

### Key Metrics

#### Business Metrics
- **User registration rate**: New users per day
- **Onboarding completion rate**: % of users completing onboarding
- **Drop-off points**: Where users abandon onboarding
- **User retention**: % of users returning after 7 days

#### Technical Metrics
- **Response time**: Average response time
- **Error rate**: % of requests with errors
- **Database performance**: Query execution time
- **Memory usage**: Application memory consumption

### Alerting Setup

#### Alert Thresholds
```ruby
# Alert on high error rate
HighErrorRateAlert.new.check if error_rate > 0.01

# Alert on slow response times
SlowResponseAlert.new.check if avg_response_time > 2

# Alert on memory usage
MemoryUsageAlert.new.check if memory_usage > 1000
```

#### Alert Channels
- **Email**: For critical issues
- **Slack**: For team notifications
- **PagerDuty**: For emergency issues
- **SMS**: For urgent alerts

---

## Troubleshooting Guide

### Common Issues

#### Database Issues
```ruby
# Check database connections
ActiveRecord::Base.connection_pool.status

# Reset connection pool
ActiveRecord::Base.connection_pool.disconnect!
ActiveRecord::Base.connection_pool.reconnect!

# Check for locked tables
SELECT * FROM pg_locks WHERE granted = false;
```

#### Performance Issues
```ruby
# Check for slow queries
SELECT query, mean_time
FROM pg_stat_statements
ORDER BY mean_time DESC
LIMIT 10;

# Check for memory leaks
ps -o pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -20
```

#### Authentication Issues
```ruby
# Check user sessions
User.where(id: current_user.id).update_all(
  last_sign_in_at: Time.current,
  current_sign_in_at: Time.current
)

# Verify email confirmation
User.find_by(email: "user@example.com")&.email_confirmed_at
```

### Debug Commands

#### Debug Mode
```ruby
# Enable debug mode
Rails.logger.level = Logger::DEBUG

# Debug ActiveRecord
ActiveRecord::Base.logger = Logger.new(STDOUT)

# Debug queries
User.where(onboarding_step: 1).explain
```

#### System Debug
```bash
# Check system resources
top -p $(pgrep -f puma)

# Check disk space
df -h

# Check network connections
netstat -an | grep :3000
```

---

## Contact Information

### Maintenance Team
- **Lead Developer**: Cuong Nguyen
- **DevOps Engineer**: [Contact Information]
- **Security Specialist**: [Contact Information]

### Support Contacts
- **General Support**: [Support Email]
- **Emergency Contact**: [Phone Number]
- **Documentation**: [Documentation Link]

### Vendor Support
- **Rails Support**: [Rails Support]
- **Database Support**: [PostgreSQL Support]
- **Hosting Support**: [Hosting Provider]

---

## Maintenance Schedule

| Frequency | Tasks | Responsible |
|-----------|-------|-------------|
| **Daily** | Health checks, log monitoring | Operations Team |
| **Weekly** | Database optimization, code quality | Development Team |
| **Monthly** | Security updates, performance tuning | Security Team |
| **Quarterly** | Architecture review, technology updates | Architecture Team |
| **Annual** | Long-term planning, disaster recovery | Management Team |

---

*Last Updated*: December 7, 2025
*Version*: 1.0.0
*Status*: ✅ Active Maintenance Guidelines
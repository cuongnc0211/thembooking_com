  # Digital Ocean Deployment Guide

Complete guide for deploying ThemBooking to Digital Ocean droplets using Kamal.

## 📋 Prerequisites Checklist

- [x] 2 DO droplets created (staging: 146.190.106.247, production: 157.230.246.140)
- [x] SSH access from laptop: `ssh root@146.190.106.247` and `ssh root@157.230.246.140`
- [x] DNS record added: `staging.thembooking.com → 146.190.106.247`
- [ ] DNS record for production: `thembooking.com → 157.230.246.140` (⚠️ REQUIRED before production deploy)
- [ ] PostgreSQL passwords set in `.kamal/secrets`

---

## 🚀 Step-by-Step Deployment

### Step 1: Prepare Staging Droplet (146.190.106.247)

```bash
# SSH into staging droplet
ssh root@146.190.106.247

# Update system packages
apt update && apt upgrade -y

# Install Docker (required by Kamal)
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
rm get-docker.sh

# Install PostgreSQL
apt install -y postgresql postgresql-contrib

# Start PostgreSQL service
systemctl enable postgresql
systemctl start postgresql

# Create database and user
sudo -u postgres psql << EOF
CREATE DATABASE thembooking_staging;
CREATE USER thembooking WITH PASSWORD 'ThemBooking@2025';
GRANT ALL PRIVILEGES ON DATABASE thembooking_staging TO thembooking;
ALTER DATABASE thembooking_staging OWNER TO thembooking;
\q
EOF

# Configure PostgreSQL to allow Docker containers to connect
# The Docker bridge network (172.17.0.0/16) needs access
echo "host all all 172.17.0.0/16 md5" | sudo tee -a /etc/postgresql/*/main/pg_hba.conf

# Configure PostgreSQL to listen on all interfaces
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/*/main/postgresql.conf

# Restart PostgreSQL to apply changes
systemctl restart postgresql

# Verify PostgreSQL is running
systemctl status postgresql

# Exit droplet
exit
```

**IMPORTANT**: Copy the password you used above and update `.kamal/secrets` file (see Step 3).

---

### Step 2: Prepare Production Droplet (157.230.246.140)

```bash
# SSH into production droplet
ssh root@157.230.246.140

# Repeat ALL commands from Step 1
# (same Docker + PostgreSQL setup with DIFFERENT password)

```bash
sudo -u postgres psql << EOF
CREATE DATABASE thembooking_production;
CREATE USER thembooking WITH PASSWORD 'ThemBookingProd@2025';
GRANT ALL PRIVILEGES ON DATABASE thembooking_production TO thembooking;
ALTER DATABASE thembooking_production OWNER TO thembooking;
\q
EOF
```

# Exit droplet
exit
```

---

### Step 3: Update Local Configuration

Edit `.kamal/secrets` file on your laptop:

```bash
# Open secrets file
nano .kamal/secrets

# Find these lines and replace CHANGE-ME with your actual passwords:
# Line ~31 (staging):
DATABASE_URL="postgresql://thembooking:YOUR-STAGING-PASSWORD@172.17.0.1:5432/thembooking_production"

# Line ~43 (production):
DATABASE_URL="postgresql://thembooking:YOUR-PRODUCTION-PASSWORD@172.17.0.1:5432/thembooking_production"
```

**Security Note**: Use DIFFERENT strong passwords for staging and production!

---

### Step 4: Verify Configuration

```bash
# Test secrets loading for staging
kamal envify -d staging

# Test secrets loading for production
kamal envify -d production

# Both should output environment variables without errors
```

---

### Step 5: Deploy to Staging

```bash
# First-time setup (installs Traefik proxy, sets up Docker networks, etc.)
kamal setup -d staging

# This will:
# - Install Traefik reverse proxy
# - Configure Let's Encrypt SSL for staging.thembooking.com
# - Build and push Docker image
# - Deploy web and worker containers
# - Run database migrations

# Watch the output for any errors
```

**Expected outcome**: App running at `https://staging.thembooking.com` with valid SSL certificate.

---

### Step 6: Verify Staging Deployment

```bash
# Check app status
kamal app details -d staging

# View live logs
kamal app logs -f -d staging

# Test the application
curl https://staging.thembooking.com/up
# Should return: OK

# Access Rails console
kamal app exec -d staging -i --reuse "bin/rails console"
# Try: User.count, Business.count, etc.

# Exit console with: exit
```

---

### Step 7: Deploy to Production (⚠️ DNS Required)

**BEFORE deploying to production:**

1. **Add DNS A Record**: `thembooking.com → 157.230.246.140`
2. **Wait for DNS propagation** (check with: `dig thembooking.com`)
3. **Verify DNS resolves correctly** (should show 157.230.246.140)

```bash
# Verify DNS is pointing correctly
dig thembooking.com +short
# Should output: 157.230.246.140

# If DNS is ready, proceed with deployment
kamal setup -d production

# Watch for successful SSL certificate issuance from Let's Encrypt
```

**Expected outcome**: App running at `https://thembooking.com` with valid SSL certificate.

---

### Step 8: Verify Production Deployment

```bash
# Check app status
kamal app details -d production

# View live logs
kamal app logs -f -d production

# Test the application
curl https://thembooking.com/up
# Should return: OK
```

---

## 🔄 Day-to-Day Deployment Workflow

After initial setup, deploy updates with:

```bash
# Deploy to staging (test changes first)
git push origin main
kamal deploy -d staging

# Verify staging works
curl https://staging.thembooking.com/up

# Deploy to production
kamal deploy -d production
```

---

## 🛠️ Common Commands

### Viewing Logs

```bash
# Staging logs (follow mode)
kamal app logs -f -d staging

# Production logs (last 100 lines)
kamal app logs --lines 100 -d production

# Worker logs only
kamal app logs -f -d staging --roles worker
```

### Rails Console Access

```bash
# Staging console
kamal app exec -d staging -i --reuse "bin/rails console"

# Production console (be careful!)
kamal app exec -d production -i --reuse "bin/rails console"
```

### Database Console

```bash
# Staging database
kamal app exec -d staging -i --reuse "bin/rails dbconsole"

# Production database
kamal app exec -d production -i --reuse "bin/rails dbconsole"
```

### Running Migrations

```bash
# Migrations run automatically during kamal deploy
# To run manually:
kamal app exec -d staging -i --reuse "bin/rails db:migrate"
```

### Rollback Deployment

```bash
# Rollback to previous version
kamal rollback -d staging

# Specify version to rollback to
kamal rollback <git-sha> -d production
```

### App Management

```bash
# Restart app (without redeploying)
kamal app restart -d staging

# Stop app
kamal app stop -d staging

# Start app
kamal app start -d staging

# View app details
kamal app details -d staging
```

---

## 🔐 Security Checklist

- [ ] PostgreSQL port 5432 is NOT exposed publicly (only to Docker bridge)
- [ ] Strong, unique passwords for staging and production databases
- [ ] `.kamal/secrets` file is git-ignored
- [ ] SSH keys are properly configured on both droplets
- [ ] DO firewall rules configured (only allow ports 22, 80, 443)

### Configure DO Firewall (Recommended)

```bash
# Via DigitalOcean web UI:
# 1. Go to Networking → Firewalls
# 2. Create firewall with rules:
#    - SSH (22): Your IP only
#    - HTTP (80): All IPv4/IPv6
#    - HTTPS (443): All IPv4/IPv6
# 3. Apply to both droplets
```

---

## 📊 Monitoring & Health Checks

### Health Check Endpoint

Both staging and production have health checks configured:

- URL: `/up`
- Interval: Every 10 seconds
- Traefik monitors this and removes unhealthy containers

### Check Container Health

```bash
# Staging health
curl https://staging.thembooking.com/up

# Production health
curl https://thembooking.com/up
```

---

## 🔄 Migrating to Managed PostgreSQL (Future)

When you need managed database (scalability, automatic backups):

### Step 1: Create DO Managed PostgreSQL

1. Go to DO Dashboard → Databases → Create Database
2. Select PostgreSQL 14+
3. Choose region (same as droplets)
4. Note the connection details

### Step 2: Update `.kamal/secrets`

```bash
# Replace line ~31 (staging):
DATABASE_URL="postgresql://doadmin:password@managed-db-host:25060/thembooking_production?sslmode=require"

# Or line ~43 (production):
DATABASE_URL="postgresql://doadmin:password@managed-db-host:25060/thembooking_production?sslmode=require"
```

### Step 3: Migrate Data (if needed)

```bash
# Dump from droplet PostgreSQL
ssh root@146.190.106.247
sudo -u postgres pg_dump thembooking_production > /tmp/dump.sql
exit

# Restore to managed DB
psql "postgresql://doadmin:password@managed-db-host:25060/defaultdb?sslmode=require" < /tmp/dump.sql
```

### Step 4: Redeploy

```bash
kamal deploy -d staging
# App now uses managed database!
```

---

## 🐛 Troubleshooting

### Problem: "Connection refused" when deploying

**Solution**: Ensure Docker is installed and running on droplet:

```bash
ssh root@146.190.106.247
systemctl status docker
# If not running: systemctl start docker
```

### Problem: SSL certificate fails to issue

**Solution**: Verify DNS is correctly pointing to droplet IP:

```bash
dig staging.thembooking.com +short
# Should show: 146.190.106.247
```

Wait 5-10 minutes for DNS propagation, then retry deployment.

### Problem: App can't connect to PostgreSQL

**Solution**: Check PostgreSQL is accepting connections from Docker:

```bash
ssh root@146.190.106.247
sudo -u postgres psql -c "\conninfo"
grep "172.17.0.0" /etc/postgresql/*/main/pg_hba.conf
# Should show: host all all 172.17.0.0/16 md5
```

### Problem: Database migration fails

**Solution**: Run migrations manually with verbose output:

```bash
kamal app exec -d staging -i --reuse "bin/rails db:migrate VERBOSE=true"
```

---

## 📞 Quick Reference

| Environment | IP Address      | Domain                      | Deploy Command             |
|-------------|-----------------|----------------------------|----------------------------|
| Staging     | 146.190.106.247 | staging.thembooking.com    | `kamal deploy -d staging`  |
| Production  | 157.230.246.140 | thembooking.com            | `kamal deploy -d production` |

---

## ✅ Post-Deployment Checklist

After successful deployment:

- [ ] App is accessible at correct domain with HTTPS
- [ ] Health check endpoint returns "OK"
- [ ] Rails console works
- [ ] Database migrations completed
- [ ] Worker is processing jobs (if applicable)
- [ ] Logs are clean (no errors)
- [ ] Test key user flows (signup, login, etc.)

---

**Last Updated**: December 27, 2024

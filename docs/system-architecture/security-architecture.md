# Security Architecture

## Multi-Layer Security Approach

### 1. Network Security

```yaml
Infrastructure:
  Cloudflare Tunnel: End-to-end encryption
  Firewall: Block unnecessary ports
  SSL/TLS: HTTPS enforcement via Let's Encrypt

Application:
  CSP: Content Security Policy headers
  HSTS: HTTP Strict Transport Security
  X-Frame-Options: Clickjacking protection
  X-Content-Type-Options: MIME type sniffing protection
```

### 2. Authentication Architecture

```ruby
class User < ApplicationRecord
  # Password hashing with bcrypt
  has_secure_password

  # Session management
  has_many :sessions, dependent: :destroy

  # Email verification
  before_create :generate_confirmation_token

  def confirm!
    update!(email_confirmed_at: Time.current, email_confirmation_token: nil)
  end
end
```

Session Controller with Security:

```ruby
class SessionsController < ApplicationController
  rate_limit to: 5, within: 1.minute, only: :create

  def create
    if user = User.authenticate_by(email_address: params[:email], password: params[:password])
      unless user.confirmed?
        redirect_to root_path, alert: "Please confirm your email"
        return
      end

      start_new_session_for user
      SecurityLog.login_attempt(user, request)
      redirect_to dashboard_path
    else
      redirect_to new_session_path, alert: "Invalid credentials"
    end
  end
end
```

**Security Features**:
- Bcrypt password hashing (never stored plain text)
- Email verification required before login
- Rate limiting (5 attempts/minute)
- Session management with secure tokens
- Login attempt logging

### 3. Authorization Patterns

```ruby
class ApplicationController < ActionController::Base
  private

  def require_authentication
    return if current_user
    redirect_to new_session_path, alert: "Please sign in"
  end

  def require_onboarding!
    return if current_user.onboarding_completed?
    redirect_to dashboard_onboarding_path, alert: "Please complete setup"
  end
end
```

Resource-Based Authorization:

```ruby
class BookingPolicy < ApplicationPolicy
  def show?
    record.branch.business.user == user
  end

  def create?
    user.business.present? && user.onboarding_completed?
  end

  def update?
    show? && user.onboarding_completed?
  end
end
```

### 4. Data Protection

Strong Parameters for Input Validation:

```ruby
def booking_params
  params.require(:booking).permit(
    :service_id,
    :booking_date,
    :booking_time,
    :customer_name,
    :customer_phone,
    :customer_email,
    :notes
  )
end

def branch_params
  params.require(:branch).permit(
    :name,
    :slug,
    :address,
    :phone,
    :capacity,
    operating_hours: {}
  )
end
```

Sensitive Data Handling:

```ruby
class User < ApplicationRecord
  # Never store plain text passwords
  has_secure_password

  # Encrypted sensitive fields (if needed)
  # attr_encrypted :phone, key: Rails.application.credentials.secret_key_base

  # Validation for email format
  validates :email_address, format: { with: URI::MailTo::EMAIL_REGEXP }
end
```

## Security Headers Implementation

```ruby
# config/application.rb
config.action_dispatch.default_headers = {
  'X-Frame-Options' => 'SAMEORIGIN',
  'X-XSS-Protection' => '1; mode=block',
  'X-Content-Type-Options' => 'nosniff',
  'X-Download-Options' => 'noopen',
  'X-Permitted-Cross-Domain-Policies' => 'none',
  'Referrer-Policy' => 'strict-origin-when-cross-origin',
  'Strict-Transport-Security' => 'max-age=31536000; includeSubDomains'
}
```

## Defense in Depth Layers

| Layer | Protection | Implementation |
|---|---|---|
| **Network** | HTTPS only | Cloudflare Tunnel + Let's Encrypt |
| **Application** | CSRF tokens | Rails middleware |
| **Authentication** | Secure sessions | Bcrypt + Session tokens |
| **Authorization** | Role-based access | Pundit policies |
| **Input** | Validation | Strong parameters + model validations |
| **SQL** | Parameterized queries | Active Record ORM |
| **Data** | Encrypted in transit | HTTPS enforced |

## Admin Panel Security

```ruby
module Admin
  class BaseController < ApplicationController
    before_action :authenticate_staff!
    before_action :require_super_admin!

    private

    def authenticate_staff!
      redirect_to root_path unless current_staff
    end

    def require_super_admin!
      redirect_to root_path unless current_staff.super_admin?
    end
  end
end
```

## Rate Limiting

```ruby
class SessionsController < ApplicationController
  rate_limit to: 5, within: 1.minute, only: :create

  def create
    # Login attempt limited to 5 per minute
  end
end
```

## Security Checklist

- [x] HTTPS enforced (Cloudflare Tunnel)
- [x] Passwords hashed with bcrypt
- [x] Email verification required
- [x] CSRF tokens on all forms
- [x] XSS protection headers
- [x] SQL injection prevention (ORM)
- [x] Rate limiting on login
- [x] Session timeout
- [x] Input validation (strong parameters)
- [x] Authorization checks before data access
- [x] Admin panel access control
- [x] Secure headers configuration

*Last Updated*: March 13, 2026
*Version*: v0.2.0

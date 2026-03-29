# Detailed Testing Patterns

This guide provides comprehensive testing patterns and best practices for the Rails monolith.

## Core Testing Principles

- Use RSpec for all tests
- **Write request specs** (in `spec/requests/`) instead of controller specs
  - Request specs test routing, response contracts, and no errors end-to-end
  - Controller specs only unit test controller methods without testing routes
- Use **factories instead of fixtures**
- **Set up test data with `let`** in describe/context blocks where possible
- Test edge cases and error conditions

## Timestamp Testing

**Always use `Timecop.freeze` and avoid exact timestamp comparisons** to prevent CI failures.

### The Problem

ActiveRecord truncates timestamps to microsecond precision when saving to database, but Ruby's `Time.current` can have nanosecond precision, causing failures like:

```
expected: 2025-09-26 00:20:23.882811848 +1000
     got: 2025-09-26 00:20:23.882811000 +1000
```

### The Solution

```ruby
# Bad - causes flaky CI failures due to precision differences
expect { service.call }.to change { record.reload.created_at }.to(Time.current)

# Good - use Timecop.freeze and compare seconds only
Timecop.freeze do
  frozen_time = Time.current
  expect { service.call }.to change { record.reload.created_at }.from(nil)
  expect(record.created_at.to_i).to eq(frozen_time.to_i)
end
```

## RSpec Message Spies

**Prefer message spies over receive expectations** for better test readability.

### The Pattern

```ruby
# Bad - not following RSpec best practices
expect(SomeClass).to receive(:method).with(args)
subject.call

# Good - use spy pattern with allow/have_received
allow(SomeClass).to receive(:method)
subject.call
expect(SomeClass).to have_received(:method).with(args)
```

### Why This Matters

- **Arrange-Act-Assert**: Spy pattern follows natural test flow
- **Clearer intent**: Setup separate from expectations
- **Better error messages**: Failures show what actually happened
- **More flexible**: Can check call order and multiple calls easily

## AdminLog Testing

**Use `AdminLog.create!` directly** instead of `AdminLog.record` for reliable test execution.

### The Pattern

```ruby
# Preferred for test mocking - works consistently
expect(AdminLog).to receive(:create!).with(target: record, acting_user: user, action: 'action_name')
```

### Why Not AdminLog.record?

- `AdminLog.record` is a service method that wraps `create!`
- Direct mocking of `create!` is more reliable in tests
- Avoids issues with method delegation and stubbing

## Example Test Structure

```ruby
require "rails_helper"

describe User do
  let(:user) { build(:user) }

  it "is valid with valid attributes" do
    expect(user).to be_valid
  end

  context "without an email" do
    let(:user) { build(:user, email: nil) }

    it "is not valid" do
      expect(user).not_to be_valid
    end
  end

  context "with duplicate email" do
    let!(:existing_user) { create(:user, email: 'test@example.com') }
    let(:user) { build(:user, email: 'test@example.com') }

    it "is not valid" do
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include('has already been taken')
    end
  end
end
```

## Testing Service Objects

### Basic Service Test

```ruby
require "rails_helper"

describe Users::Deactivator do
  let(:user) { create(:user, state: 'active') }
  let(:admin) { create(:user, :staff) }
  let(:service) { described_class.new(user, reason: 'Policy violation', user: admin) }

  describe '#call' do
    it 'deactivates the user' do
      result = service.call

      expect(result).to be_success
      expect(user.reload.state).to eq('inactive')
    end

    it 'logs the action' do
      allow(AdminLog).to receive(:create!)

      service.call

      expect(AdminLog).to have_received(:create!).with(
        target: user,
        acting_user: admin,
        action: 'deactivate'
      )
    end

    context 'when user is already inactive' do
      let(:user) { create(:user, state: 'inactive') }

      it 'returns failure result' do
        result = service.call

        expect(result).to be_failure
        expect(result.error.code).to eq(:already_inactive)
      end
    end
  end
end
```

## Testing Controllers (Request Specs)

### Basic Request Spec

```ruby
require "rails_helper"

describe "Tasks API", type: :request do
  let(:user) { create(:user) }
  let(:headers) { auth_headers(user) }

  describe "POST /tasks" do
    let(:task_params) { { title: 'Clean my house', price: 100 } }

    it 'creates a new task' do
      expect {
        post '/tasks', params: { task: task_params }, headers: headers
      }.to change(Task, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(json_response['title']).to eq('Clean my house')
    end

    context 'with invalid params' do
      let(:task_params) { { title: '' } }

      it 'returns validation errors' do
        post '/tasks', params: { task: task_params }, headers: headers

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['errors']).to include('title')
      end
    end

    context 'without authentication' do
      it 'returns unauthorized' do
        post '/tasks', params: { task: task_params }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
```

## Testing Background Jobs

### Sidekiq Job Test

```ruby
require "rails_helper"

describe UserCleanupJob do
  let(:user) { create(:user, state: 'inactive', updated_at: 2.years.ago) }

  describe '#perform' do
    it 'cleans up user data' do
      expect {
        described_class.new.perform(user.id)
      }.to change { user.orders.count }.to(0)
    end

    it 'sends cleanup email' do
      expect {
        described_class.new.perform(user.id)
      }.to have_enqueued_mail(UserMailer, :account_cleanup)
    end

    context 'when user is active' do
      let(:user) { create(:user, state: 'active') }

      it 'does not clean up data' do
        expect {
          described_class.new.perform(user.id)
        }.not_to change { user.orders.count }
      end
    end

    context 'when user not found' do
      it 'logs warning and does not raise' do
        expect(Rails.logger).to receive(:warn).with(/not found/)

        expect {
          described_class.new.perform(999999)
        }.not_to raise_error
      end
    end
  end
end
```

## Testing with Factories

### Basic Factory Usage

```ruby
# Build without saving (for validation tests)
user = build(:user)

# Create and save (for database tests)
user = create(:user)

# Create multiple records
users = create_list(:user, 3)

# Override attributes
user = create(:user, email: 'specific@example.com', state: 'inactive')

# Use traits
admin_user = create(:user, :staff, :admin_login)

# Build with associations
task = build(:task, user: user)
task_with_bids = create(:task, :with_bids)
```

### Factory Best Practices

- **Use `build` when possible** - faster than `create`
- **Only `create` when needed** - for tests requiring database state
- **Use traits for variations** - keeps factories DRY
- **Set up associations explicitly** - makes tests clearer
- **Use `let!` for data that must exist** - forces creation before test

## Testing with Time

### Using Timecop

```ruby
# Freeze time
Timecop.freeze(Time.new(2024, 1, 15, 10, 0, 0)) do
  # Code runs with frozen time
  expect(Time.current).to eq(Time.new(2024, 1, 15, 10, 0, 0))
end

# Travel in time
Timecop.travel(1.day.from_now) do
  # Code runs 1 day in the future
end

# Clean up (automatically handled with block form)
Timecop.return
```

### Testing Time-Dependent Logic

```ruby
describe 'task expiration' do
  let(:task) { create(:task, expires_at: 2.days.from_now) }

  it 'is not expired before expiration date' do
    expect(task.expired?).to be false
  end

  it 'is expired after expiration date' do
    Timecop.travel(3.days.from_now) do
      expect(task.expired?).to be true
    end
  end
end
```

## Testing Database Transactions

### Transaction Rollback Tests

```ruby
describe 'payment processing with rollback' do
  let(:payment) { create(:payment, amount: 100) }
  let(:account) { create(:account, balance: 500) }

  it 'rolls back on failure' do
    allow(PaymentGateway).to receive(:charge).and_raise(PaymentError)

    expect {
      service.process_payment(payment, account)
    }.to raise_error(PaymentError)

    expect(account.reload.balance).to eq(500)  # Balance unchanged
    expect(payment.reload.state).to eq('pending')  # State unchanged
  end
end
```

## Common Test Helpers

### Request Spec Helpers

```ruby
# spec/support/request_helpers.rb
module RequestHelpers
  def json_response
    JSON.parse(response.body)
  end

  def auth_headers(user)
    token = JWT.encode({ user_id: user.id }, Rails.application.credentials.secret_key_base)
    { 'Authorization' => "Bearer #{token}" }
  end
end

RSpec.configure do |config|
  config.include RequestHelpers, type: :request
end
```

### Factory Helpers

```ruby
# spec/support/factory_helpers.rb
module FactoryHelpers
  def attributes_for_user(**overrides)
    attributes_for(:user).merge(overrides)
  end
end

RSpec.configure do |config|
  config.include FactoryHelpers
end
```

## Performance Testing

### Testing N+1 Queries

```ruby
it 'does not have N+1 queries' do
  create_list(:task, 3, :with_bids)

  expect {
    get '/tasks', headers: headers
  }.to perform_constant_number_of_queries
end
```

### Testing Query Performance

```ruby
it 'loads users efficiently' do
  create_list(:user, 100)

  expect {
    User.includes(:tasks).to_a
  }.to make_database_queries(count: 2)  # 1 for users, 1 for tasks
end
```

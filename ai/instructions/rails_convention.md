# ThemBooking Ruby on Rails conventions

You are helping develop a Ruby on Rails API. The following technologies are used:

- Sidekiq for processing of jobs
- Memcache for in-memory caching
- Postgres for the majority

## Project structure

Aside from adhering to a typical Ruby on Rails project setup, the following patterns are utilised:

- `app/services/`: Services contain business logic and are used to encapsulate complex operations that involve models or external services. Services should be stateless and reusable.
- `app/workers/`: Workers are used for background processing.
- `app/grpc/`: gRPC services are defined here.

## General principles

Follow these guidelines when generating code:

- Prioritise simple, maintainable code over clever solutions
- Follow Rails conventions and "The Rails Way"
- Prefer explicit over implicit
- Use proper Ruby idioms
- Write code that is easy to test

## Identifier lookups for Users and Tasks

- Use `.find_with_identifier` over any other ActiveRecord lookup for User and Task models


```ruby
id = "some-id"

# Good
Task.find_with_identifier(id)

# Bad
Task.find_by(id: id)
```

## Code location

- Most code should **not** live in `app/models/` or `app/controllers/` but rather within `app/services/` or within Gems and are explicitly required by the business logic in `app/services/`

## Code style

- Follow Rubocop rules in `.rubocop.yml`
- Add comments only when necessary to explain "why", not "what"

## Models

- Use ActiveRecord validations for data integrity
- Use callbacks sparingly and with caution
- Add proper indexes for database performance
- Add scopes for common query patterns

## Testing

- Use RSpec for testing
- Write unit tests for models
- Write request tests for controllers
- Use factories instead of fixtures
- Test edge cases and error conditions
- Perform factory setup in the `describe` or `context` block where possible using `let`

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
end
```

#### Request/controller specs and integration testing

- We run integration tests with RSpec. These test that the route responds to the request, that the response matches the contract (we don't validate the contract for the request at the moment), and that there are no errors
- To do this, we use request specs and avoid using controller specs. Controller specs do not test that the route is responding and meeting the contract as expected, they just unit test the output of the functions in the controller. In our case, also testing the routing is a low-cost thing to include in our integration tests (in some very low-latency apps that might not make as much sense)
- Before request specs were introduced to RSpec we had a lot of controller tests in `spec/controllers/` and we added the request tests to that folder. So there is a mix of spec types there. Our convention now is to migrate any request tests out to `spec/requests/` as we find them with our convention checker.

## Things to avoid

### Dynamic method creation

While this is a very powerful tool of Ruby, we generally want to avoid doing things like this as it makes understanding the code much harder. For example a call to a dynamically defined user.has_download_permission? might be being investigated and if the developer can’t find and function definition called “def has_download_permission?” the might think it doesn’t exist and remove it.

### ActiveRecord callbacks

These are great when you are starting out with a simple Rails app. But they tend to turn into hard to understand implicit behaviour of your models that is hard to follow.

It is much better to explicitly create service classes like an OfferCreator class that takes care of the offer creation, the audit logging, the async updating of Tasker stats, etc. That way anyone creating an offer can use that class and all of the creation logic is clearly visible in that class and easily understandable and testable.

### Background scheduling in the future

The standard method for scheduling background jobs is perform_async which schedules the job to run as soon as it can be picked up next (usually within a couple of seconds unless there is a problem with queueing).

An anti-pattern is scheduling a job more than a minute into the future. This is because our persistence layer for background jobs is Redis. Redis is primarily built for speed and not durability. This means you should should avoid relying on the data within Redis to be persisted. Accidental deletions and shutdowns can cause all data in Redis to disappear. You want to minimise that risk surface area by only having things live a few seconds within Redis.

If you want to run a job in 1 day or 1 month from now, you should think about designing it as a cronjob instead. This means some state needs to be recorded in a database table to be able to calculate the time “from” and creating a cronjob that runs with some frequency checking for records to process. Some examples:

- Find any cancellation records that are pending for more than 1 day but no warning sent -> send a reminder
- Find any pending cancellations older than 2 days, where a warning has been sent -> accept the cancellation
- Find any reviews that are still pending after a day since the other party input a review and no reminder has been sent -> send a reminder

### Removing columns from tables

When removing a column from a table, the change should be split into two distinct changes:

1. Removing all uses of that column in the codebase, and add the column to ignored_columns in the model.
2. The removal of the column using a database migration

By removing columns from a table in this way, we prevent failures during deployment and thus database migrations running where we can have old code running referencing the columns while the column has been removed in the migration.

### gRPC Service Specs

- Use the `grpc_call` helper to make gRPC requests.
- Describe the service class directly (e.g., `Admin::V1::AuthService`), not the `GrpcService` implementation.
- Use `build_stubbed` for factories to avoid hitting the database.

**Example: `spec/requests/grpc/admin/v1/auth_service_spec.rb`**

```ruby
# frozen_string_literal: true

require 'rails_helper'

describe Admin::V1::AuthService do
  let(:decoded_access_token) { { 'email' => 'test@example.com', 'exp' => 1.hour.from_now.to_i } }
  let(:encoded_access_token) { Base64.strict_encode64(decoded_access_token.to_json) }
  let(:user) { build_stubbed(:user, email: 'test@example.com', first_name: 'Test', last_name: 'User') }
  let(:authenticator) { instance_double(Admin::Auth::AdminUserOktaAuthenticator) }
  let(:default_request) { { encoded_access_token: encoded_access_token } }

  def do_request(request: default_request)
    grpc_call(
      described_class::Service,
      :Authenticate,
      request,
      { 'x-api-key': ENV.fetch('ADMIN_PANEL_SHARED_TOKEN', nil) },
    )
  end

  before do
    allow(Admin::Auth::AdminUserOktaAuthenticator).to receive(:new).with(decoded_access_token).and_return(authenticator)
  end

  context 'when authentication is successful' do
    before do
      allow(authenticator).to receive(:authenticate).and_return(Result::Success.new(object: user))
      allow(user).to receive(:list_permissions).and_return({ 'login' => true, 'post_task' => true })
    end

    it 'returns a valid response' do
      response = do_request
      expect(response).to be_a(Admin::V1::AuthenticateResponse)
      expect(response.user).to have_attributes(
        id: user.id.to_s,
        email: user.email,
        first_name: user.first_name,
        last_name: user.last_name,
        permissions: contain_exactly('login', 'post_task')
      )
    end
  end
end
```

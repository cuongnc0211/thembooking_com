# Database Migration Best Practices

This guide provides comprehensive information for creating safe, zero-downtime database migrations.

## Core Principles

- **Use `disable_ddl_transaction!` for concurrent operations** to avoid blocking
- **Add indexes concurrently** in production with `algorithm: :concurrently`
- **Test migrations both up and down** to ensure they're reversible
- **Use `change` method when possible** for automatic rollback generation
- **Column removal requires two-step process** to prevent deployment failures

## Safe Migration Patterns

### Adding Columns

```ruby
class AddStatusToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :status, :string
    add_index :users, :status  # Add index if column will be queried
  end
end
```

### Adding NOT NULL Constraints Safely

**Never add NOT NULL constraint directly** - it requires a table lock.

```ruby
# Step 1: Add column as nullable
class AddEmailToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :email, :string
  end
end

# Step 2: Backfill data (separate migration or background job)
class BackfillUserEmails < ActiveRecord::Migration[7.0]
  def up
    User.find_each do |user|
      user.update_column(:email, generate_email(user))
    end
  end

  def down
    # No need to revert backfill
  end
end

# Step 3: Add NOT NULL constraint (after verifying all rows have data)
class AddNotNullToUserEmail < ActiveRecord::Migration[7.0]
  def change
    change_column_null :users, :email, false
  end
end
```

### Adding Indexes Concurrently

```ruby
class AddIndexToTasksOnState < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_index :tasks, :state, algorithm: :concurrently
  end
end
```

**Why concurrent indexes?**
- Standard indexes lock the table during creation
- Concurrent indexes allow reads/writes during creation
- Takes longer but zero downtime

### Removing Columns (Two-Step Process)

**Step 1: Remove code references and ignore column**

```ruby
# app/models/user.rb
class User < ApplicationRecord
  self.ignored_columns = [:deprecated_field]
end
```

Deploy this change to production first.

**Step 2: Remove column in separate deployment**

```ruby
class RemoveDeprecatedFieldFromUsers < ActiveRecord::Migration[7.0]
  def change
    remove_column :users, :deprecated_field, :string
  end
end
```

**Why two steps?**
- Running code may still reference the column
- `ignored_columns` tells Rails to skip the column
- After deploy, safe to remove from database

### Adding Foreign Keys

**For large tables**, add foreign key without validation first, then validate separately:

```ruby
class AddUserIdToTasks < ActiveRecord::Migration[7.0]
  def change
    add_reference :tasks, :user, foreign_key: { validate: false }
  end
end

# Separate migration to validate
class ValidateUserIdOnTasks < ActiveRecord::Migration[7.0]
  def up
    validate_foreign_key :tasks, :users
  end

  def down
    # No-op - validation can be removed without issue
  end
end
```

### Renaming Columns

**Never rename columns directly** - requires two-step process:

```ruby
# Step 1: Add new column and backfill
class AddNewNameToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :new_name, :string
  end
end

# Step 2: Backfill data (can be background job)
class BackfillNewNameFromOldName < ActiveRecord::Migration[7.0]
  def up
    User.find_each do |user|
      user.update_column(:new_name, user.old_name)
    end
  end
end

# Step 3: Update code to use new column (deploy)

# Step 4: Remove old column (after verifying new column works)
class RemoveOldNameFromUsers < ActiveRecord::Migration[7.0]
  def change
    remove_column :users, :old_name, :string
  end
end
```

## Migration Testing

### Test Both Directions

```ruby
require 'rails_helper'

describe AddStatusToUsers, type: :migration do
  it 'adds status column' do
    migrate(:up)

    expect(User.column_names).to include('status')
  end

  it 'removes status column on rollback' do
    migrate(:up)
    migrate(:down)

    expect(User.column_names).not_to include('status')
  end
end
```

### Test Data Migrations

```ruby
describe BackfillUserEmails, type: :migration do
  let!(:user_without_email) { create(:user, email: nil) }

  it 'backfills missing emails' do
    migrate(:up)

    expect(user_without_email.reload.email).to be_present
  end
end
```

## Strong Migrations Integration

This project uses the `strong_migrations` gem to catch dangerous operations.

### Common Warnings

**Adding column with default:**
```ruby
# Bad - locks table in old Postgres versions
add_column :users, :admin, :boolean, default: false

# Good - add column, then set default
add_column :users, :admin, :boolean
change_column_default :users, :admin, false
```

**Adding index without concurrent:**
```ruby
# Bad - locks table during index creation
add_index :users, :email

# Good - uses concurrent index creation
disable_ddl_transaction!
add_index :users, :email, algorithm: :concurrently
```

**Removing column:**
```ruby
# Bad - breaks running code
remove_column :users, :name

# Good - use two-step process
# 1. Ignore column in model
# 2. Remove in separate deployment
```

### Bypassing Strong Migrations

Only when you understand the risks:

```ruby
class MySafeMigration < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      # Operation that strong_migrations flags but you've verified is safe
      remove_column :users, :deprecated_field
    end
  end
end
```

## Zero Downtime Migrations

This project uses the `zero_downtime_migrations` gem for additional safety.

### Key Features

- **Prevents dangerous operations** during migrations
- **Ensures migrations are reversible** when possible
- **Catches common mistakes** before they reach production

### Common Patterns

**Change column type:**
```ruby
# Bad - requires table rewrite
change_column :users, :age, :bigint

# Good - create new column, backfill, swap
add_column :users, :age_bigint, :bigint
# Backfill in background job
# Swap columns in code
# Remove old column
```

## Large Table Migrations

### Background Data Migrations

For large tables (>1M rows), use background jobs:

```ruby
class BackfillUserEmails < ActiveRecord::Migration[7.0]
  def up
    # Don't block migration
    BackfillUserEmailsJob.perform_later
  end

  def down
    # No-op
  end
end

# app/jobs/backfill_user_emails_job.rb
class BackfillUserEmailsJob < ApplicationJob
  def perform
    User.where(email: nil).find_in_batches(batch_size: 1000) do |batch|
      batch.each do |user|
        user.update_column(:email, generate_email(user))
      end
    end
  end
end
```

### Batch Processing

```ruby
def up
  User.in_batches(of: 1000) do |batch|
    batch.update_all(migrated: true)
    sleep 0.1  # Avoid overwhelming database
  end
end
```

## Migration Timeouts

For long-running migrations:

```ruby
class LongRunningMigration < ActiveRecord::Migration[7.0]
  def up
    # Increase timeout for this migration
    connection.execute("SET statement_timeout = '60min'")

    # Long-running operation
    add_index :large_table, :column, algorithm: :concurrently

    # Reset timeout
    connection.execute("SET statement_timeout = '30s'")
  end
end
```

## Reversible Migrations

### Using `up` and `down`

```ruby
class ComplexMigration < ActiveRecord::Migration[7.0]
  def up
    add_column :users, :status, :string
    User.update_all(status: 'active')
  end

  def down
    remove_column :users, :status
  end
end
```

### Using `reversible`

```ruby
class ComplexMigration < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :status, :string

    reversible do |dir|
      dir.up do
        User.update_all(status: 'active')
      end

      dir.down do
        # No need to revert data changes
      end
    end
  end
end
```

## Common Gotchas

### Touching Production Tables During Migrations

```ruby
# Bad - loads entire table into memory
User.all.each { |u| u.update(status: 'active') }

# Good - batch processing
User.find_each(batch_size: 1000) { |u| u.update(status: 'active') }

# Better - bulk update
User.update_all(status: 'active')
```

### Depending on Model Code

```ruby
# Bad - model code may change in future
class BackfillStatus < ActiveRecord::Migration[7.0]
  def up
    User.all.each { |u| u.calculate_status! }  # What if method is removed?
  end
end

# Good - inline logic in migration
class BackfillStatus < ActiveRecord::Migration[7.0]
  def up
    User.find_each do |user|
      status = if user.active?
                 'active'
               else
                 'inactive'
               end
      user.update_column(:status, status)
    end
  end
end
```

### Not Testing Rollback

```ruby
# Always implement down or make migration irreversible
class IrreversibleMigration < ActiveRecord::Migration[7.0]
  def up
    drop_table :old_table
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
```

## Migration Checklist

Before merging a migration:

- [ ] Tested locally with `rails db:migrate`
- [ ] Tested rollback with `rails db:rollback`
- [ ] Verified zero downtime (no table locks on large tables)
- [ ] Used concurrent indexes for new indexes
- [ ] Used two-step process for removing columns
- [ ] Backfilled data before adding NOT NULL
- [ ] Added appropriate timeouts for long operations
- [ ] Checked for strong_migrations warnings
- [ ] Reviewed in production-like environment
- [ ] Documented any manual steps required

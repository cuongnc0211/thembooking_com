# ThemBooking — CLAUDE.md

This is the development guide for Claude Code when working in this repository.
Read this file fully before making any changes.

Read @ai/instruction.md for general instruction
@ai/instructions/rails_conventions.md

## Context Loading Guide

Most instruction files are loaded automatically via subdirectory `CLAUDE.md` files when you navigate into the relevant directory. Others can be read on demand.

| Working On | Instruction File | Auto-loaded When In |
|------------|-----------------|---------------------|
| Sidekiq workers, background jobs | `ai/instructions/sidekiq-queues.md` | `app/workers/` |
| Detailed test patterns | `ai/instructions/testing-patterns.md` | `spec/` |
| Database migrations | `ai/instructions/database-migrations.md` | `db/migrate/` |

---

## Project Overview

**ThemBooking** is a SaaS booking platform for barber shops and hair salons in Vietnam.
It is a Ruby on Rails monolith with Hotwire (Turbo + Stimulus) for most UI interactions,
React on Rails for heavy UX pages, and TailwindCSS for styling.

Target users: barber shop owners and their customers in Vietnam (Vietnamese language).

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Ruby on Rails (latest stable) |
| Frontend | Hotwire (Turbo + Stimulus) + TailwindCSS |
| Heavy UX pages | React on Rails (react-rails or Shakapacker) |
| Background jobs | Sidekiq + Redis |
| Database | PostgreSQL |
| File storage | Cloudflare R2 |
| Email | Resend |
| Deployment | Railway (production + staging environments) |

---

## Architecture Notes

- **Default to Hotwire** for new UI features. Only use React for pages that require
  complex client-side state (e.g. booking calendar, drag-and-drop interfaces).
- **Stimulus controllers** live in `app/javascript/controllers/`.
  Name them after the feature: `booking_calendar_controller.js`, `pricing_controller.js`.
- **Turbo Frames & Streams** are preferred over full-page reloads for CRUD operations.
- **React components** live in `app/javascript/components/`. Use functional components
  with hooks only. No class components.
- **Sidekiq jobs** live in `app/jobs/`. All external API calls (Zalo, Resend, SMS)
  must be performed inside jobs, never in the request cycle.

---

## Database Rules

> ⚠️ Always ask before modifying the database schema.

- **Never run `rails db:migrate` automatically.** Show the migration file and ask for
  confirmation before running it.
- **Never drop or rename columns** without explicit instruction. Add new columns instead
  and migrate data separately.
- **Always add indexes** for foreign keys and columns used in `where` clauses.
- When generating migrations, review existing schema (`db/schema.rb`) first to avoid
  conflicts or redundancy.
- Use **PostgreSQL-specific features** where appropriate (jsonb, array columns, etc.).

---

## i18n Rules

> All user-facing strings must use i18n. No hardcoded strings in views or mailers.

- Locale files: `config/locales/vi.yml` (Vietnamese), `config/locales/en.yml` (English + admin/dev UI)
- Vietnamese (`vi`) and English (`en`) are locales for end-user facing views .
- English (`en`) is used for admin dashboards and internal tooling.
- Always use `t('key')` or `I18n.t('key')` — never hardcode Vietnamese or English strings for end-user facing views.(Admin panel can use hardcode string)
  in `.erb`, `.html`, mailer templates, or flash messages.
- When adding a new string, add it to **both** `vi.yml` and `en.yml`.
- Locale key naming convention: `controller.action.element`
  e.g. `bookings.new.title`, `pricing.hero.subtitle`

---

## Testing Rules

> Always write tests. Do not consider a task complete without test coverage.

### Setup
- **RSpec** for all tests
- **FactoryBot** for test data — never use `Model.create` directly in specs
- **Capybara + Selenium** for system tests
- **Automation testing** is a planned roadmap item — write system specs in a way
  that can be extended into a CI automation pipeline later (avoid `sleep`, use
  `have_content` / `have_css` with proper Capybara waits instead)

### What to test
- **Models**: validations, scopes, business logic methods
- **Services / POROs**: unit test all public methods
- **Controllers / Requests**: test happy path + main error cases
- **System tests**: write for any new user-facing flow (booking, auth, pricing page CTAs)

### Conventions
```ruby
# Use let/let! consistently
# Use described_class instead of repeating the class name
# Use context/describe blocks to group scenarios clearly

describe Booking do
  describe '#confirmable?' do
    context 'when booking is pending' do
      it 'returns true' do ...
    end
    context 'when booking is already confirmed' do
      it 'returns false' do ...
    end
  end
end
```

- Run tests before marking a task done: `bundle exec rspec spec/path/to/spec.rb`
- For system tests: `bundle exec rspec spec/system/`

---

## Git Workflow

```
master        → production (Railway production env)
staging       → staging (Railway staging env)
feature/*     → feature branches, branched from master
```

### Branch rules
1. Always branch from `master`: `git checkout -b feature/my-feature master`
2. Test on `staging` before opening a PR:
   - Merge feature branch into `staging` to deploy and verify
   - `staging` is a **throwaway test branch** — it gets reset regularly
3. Open a **Pull Request** against `master` after staging verification
   - PR description should summarize what changed and how it was tested
   - At least one review before merging (self-review is acceptable for solo work)
4. Merge to `master` using **squash merge** only:
   `git merge --squash feature/my-feature`
5. Write a clear, single-line squash commit message:
   `feat: add pricing page with billing toggle and FAQ accordion`

### Commit message format
```
feat: short description      # new feature
fix: short description       # bug fix
refactor: short description  # refactor, no behavior change
chore: short description     # deps, config, tooling
test: short description      # adding/fixing tests
```

---

## Code Style

### Ruby
- Follow standard Rails conventions
- Prefer **service objects** for business logic over fat models or fat controllers
- Service objects in `app/services/`, named as verbs: `CreateBooking`, `SendReminderNotification`
- Use keyword arguments for methods with 2+ parameters
- Avoid `rescue Exception` — rescue specific error classes only

### Rails
- Use **strong parameters** in controllers — never `params.permit!`
- Scopes in models should be chainable and return `ActiveRecord::Relation`
- Avoid N+1 queries — use `includes`, `preload`, or `eager_load` as appropriate
- Background jobs should be **idempotent** — safe to run more than once

### JavaScript / Stimulus
- One controller per feature concern
- Use `data-action`, `data-target` conventions strictly
- No inline JavaScript in `.erb` files

### TailwindCSS
- Use Tailwind utility classes directly in views
- Extract repeated patterns into components or partials, not custom CSS classes
- Dark/inverted card pattern for featured elements (e.g. Pro pricing card)

---

## External Services

### Resend (Email)
- All emails go through Resend via `ActionMailer`
- Mailer classes in `app/mailers/`
- Never send email synchronously — always enqueue via Sidekiq

### Cloudflare R2 (Storage)
- Use ActiveStorage with R2 as the backend
- Never store files locally in production

### Zalo / SMS (Reminders)
- Reminder notifications are sent via Sidekiq jobs
- Jobs live in `app/jobs/notifications/`
- Wrap all Zalo/SMS API calls in begin/rescue and log failures — never raise to the user

---

## Environments

| Environment | Branch | URL |
|-------------|--------|-----|
| Production | `master` | thembooking.vn |
| Staging | `staging` | staging.thembooking.vn |

- **Never test against production data**
- Staging environment mirrors production config — use it to verify before merging to master
- Environment variables are managed in Railway dashboard — do not commit `.env` files

---

## Common Commands

```bash
# Start dev server, 2 commands:
bin/dev
rails s

# Run all tests
bundle exec rspec

# Run specific spec
bundle exec rspec spec/models/booking_spec.rb

# Run system tests
bundle exec rspec spec/system/

# Rails console
rails c

# Check for N+1 queries (Bullet gem)
# Enabled in development — check logs

# Sidekiq (background jobs)
bundle exec sidekiq
```

---

## Do Nots

- ❌ Do not run `db:migrate` without asking first
- ❌ Do not hardcode user-facing strings — always use i18n
- ❌ Do not make external API calls in the request cycle — use jobs
- ❌ Do not use `rails generate scaffold` — it creates too many files
- ❌ Do not commit `.env`, credentials, or API keys
- ❌ Do not introduce new gems without checking if existing tooling can solve the problem
- ❌ Do not write React for something Hotwire can handle simply
- ❌ Do not merge directly to `master` without testing on `staging` first

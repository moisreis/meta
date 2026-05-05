---
description: "Use when designing application structure, creating service objects, query objects, form objects, presenters, serializers, or establishing architectural patterns. Covers layer responsibilities, directory structure, dependency flow, error handling, and the layer interaction matrix. Mandatory for all architectural decisions."
name: "Rails Architecture Standard"
applyTo: ["app/services/**/*.rb", "app/queries/**/*.rb", "app/forms/**/*.rb", "app/presenters/**/*.rb", "app/serializers/**/*.rb", "app/validators/**/*.rb", "app/errors/**/*.rb", "config/initializers/**/*.rb"]
---

# Ruby on Rails Architecture Standard

**RULE: Every architectural decision must maximize isolation, explicitness, and stability under change. Layers have precisely defined responsibilities. Violations are structural defects, not style preferences.**

---

## Three Architectural Axioms

Every structural decision must satisfy at least one of these. If it doesn't, it shouldn't be made.

### Axiom 1: Isolation
Each component must be independently understandable, independently testable, and independently replaceable. A change to one component must not silently require changes elsewhere.

### Axiom 2: Explicitness
The flow of data and control must be traceable by reading the code. Implicit behavior — metaprogramming, callbacks with distant side effects, global state — is a maintenance liability.

### Axiom 3: Stability Under Change
Good architecture confines change. A new payment processor should require changes only in the payment layer. If a business change fans out across six files in four directories, the architecture is wrong.

---

## Directory Structure (Mandatory)

The following structure MUST be maintained. Directories marked **[custom]** are not Rails-generated and MUST be created manually.

```
app/
├── controllers/           ← HTTP request handling only
├── forms/                 # [custom] Complex/multi-model input validation
├── jobs/                  ← Background job dispatch (thin wrapper pattern)
├── models/                ← Data shape, associations, scopes, data-level computations
├── presenters/            # [custom] View-facing formatting and display logic
├── queries/               # [custom] Encapsulated, reusable database queries
├── serializers/           # [custom] API response serialization
├── services/              # [custom] Business logic orchestration
├── validators/            # [custom] Reusable custom validation classes
├── errors/                # [custom] Domain error hierarchy
└── views/

config/
├── initializers/          ← Application boot logic, third-party configuration
├── environments/          ← Environment-specific settings (log levels, feature flags)
└── credentials/           ← Encrypted secrets per environment

db/
├── migrate/               ← Schema migrations ONLY — no logic, no data manipulation
└── data/                  # [custom] Data-only migrations (data-migrate gem)

docs/
├── architecture.md        ← This standard's runtime companion
├── api_contracts.md       ← API endpoints, versioning, contracts
├── setup.md               ← Developer onboarding guide
└── adr/                   # [custom] Architecture Decision Records
```

### Placement Rules

| What | Where | Never |
|---|---|---|
| Business logic | `app/services/` | `app/models/`, `app/controllers/`, `lib/` |
| Database queries | `app/queries/` | Inline in controllers or model methods |
| Complex input handling | `app/forms/` | Models, controllers |
| View formatting | `app/presenters/` | Models, controllers, helpers |
| API serialization | `app/serializers/` | Controllers, models, views |
| Custom validation | `app/validators/` | Inline in models |
| Application boot | `config/initializers/` | `config/application.rb`, `config/environments/` |
| Domain errors | `app/errors/` | Scattered throughout |

> **RULE:** `lib/` is for framework-agnostic code that could theoretically be extracted into a gem. Application business logic does not belong in `lib/`.

---

## Layer Interaction Matrix (Mandatory)

This table defines exactly which layers may call which other layers. **Any call not listed here is forbidden.**

| Caller | May Call | MUST NOT Call |
|---|---|---|
| **Controller** | Service Object, Query Object (`find`), Presenter | Model business methods, external clients, other controllers |
| **Service Object** | Model, Query Object, Form Object, other Services, external client wrappers | Controller, Presenter, Serializer |
| **Query Object** | Model (ActiveRecord only) | Service Object, Controller, Presenter |
| **Form Object** | Validator classes only | Model, Service Object, Controller |
| **Presenter** | Model (read-only), Helpers | Service Object, Query Object, Controller |
| **Serializer** | Model (read-only), Presenter | Service Object, Query Object, Controller |
| **Job** | Service Object, Model (lookup only) | Controller, Presenter, Serializer |
| **Model** | — (nothing outside its own class) | Service Object, Controller, Presenter, external clients |

> **Read strictly.** A model calling a service is an inverted dependency graph. A controller calling a query bypasses the service layer. Both are defects.

---

## Layer Responsibilities

### Models

**Models own:** Data shape, constraints, associations, simple named scopes, data-level computations, callbacks for data integrity

**Models MUST NOT own:** Business workflows, cross-model side effects, HTTP concerns, mailer calls, external API calls

```ruby
# ✓ CORRECT
class Invoice < ApplicationRecord
  belongs_to :customer
  has_many :line_items, dependent: :destroy

  validates :status, presence: true, inclusion: { in: %w[draft sent paid void] }

  scope :overdue,  -> { where(status: :sent).where("due_on < ?", Date.current) }
  scope :for_year, ->(year) { where(issued_on: year.beginning_of_year..year.end_of_year) }

  def total_cents
    subtotal_cents + tax_cents
  end
end

# ✗ WRONG: Business workflow, cross-model side effect
after_create :send_email, :reserve_inventory
def mark_paid!
  update!(status: :paid)
  customer.update!(outstanding_balance: ...)
end
```

### Controllers

**Controllers own:** Request/response handling, directing requests to one service, strong parameters

**Controllers MUST NOT own:** Business logic, direct queries beyond `find`/`find_by`, multiple service calls per action, conditional routing logic

```ruby
# ✓ CORRECT: One service call per action
def create
  result = OrderCreationService.call(order_params, actor: current_user)
  if result.success?
    redirect_to result.order, notice: "Created"
  else
    @form = result.form
    render :new, status: :unprocessable_entity
  end
end

# ✗ WRONG: Multiple operations, conditional logic
def create
  @order = Order.new(order_params)
  if @order.save
    @order.update(status: :confirmed)
    UserMailer.order_confirmation(@order).deliver_later
    redirect_to @order
  else
    render :new
  end
end
```

### Service Objects

**Name after the operation, not the resource:** `OrderCreationService` ✓, `OrderService` ✗

**Interface: Every service MUST expose a single class-level `call` method.**

**Result Pattern: Return a `Result` struct — never raise exceptions for business failures.**

```ruby
class OrderCreationService
  Result = Struct.new(:success?, :order, :form, keyword_init: true)

  # @param params [Hash] Order parameters
  # @param actor [User] The user performing the action
  # @return [Result]
  def self.call(params, actor:)
    new(params, actor: actor).call
  end

  def initialize(params, actor:)
    @params = params
    @actor = actor
    @form = OrderForm.new(params)
  end

  def call
    return failure unless @form.valid?

    order = nil
    ActiveRecord::Base.transaction do
      order = Order.create!(@form.to_model_attributes.merge(created_by: @actor))
      InventoryReservationService.call(order)
    end

    OrderConfirmationJob.perform_later(order.id)

    success(order)
  end

  private

  def success(order) = Result.new(success?: true, order: order, form: @form)
  def failure        = Result.new(success?: false, order: nil, form: @form)
end
```

### Query Objects

**When to create:** Any query with multiple scopes, joins, subqueries, or complex `WHERE` clauses. Simple single-criterion scopes belong on the model.

**Interface: MUST return `ActiveRecord::Relation`, never an array. Returning arrays breaks pagination and chaining.**

```ruby
class OverdueInvoicesQuery
  def self.call(customer, currency: nil)
    new(customer, currency: currency).call
  end

  def initialize(customer, currency: nil)
    @customer = customer
    @currency = currency
  end

  def call
    relation = base_relation
    relation = relation.where(currency: @currency) if @currency.present?
    relation
  end

  private

  def base_relation
    Invoice
      .joins(:customer)
      .where(customer: @customer, status: :sent)
      .where("due_on < ?", Date.current)
      .order(due_on: :asc)
  end
end
```

### Form Objects

**When to create:** Multi-step forms, multi-model forms, or input that doesn't map directly to one model

**Must define:** `to_model_attributes` method that returns a hash safe to pass to `create!`

```ruby
class OrderForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :delivery_address, :string
  attribute :notes, :string

  validates :delivery_address, presence: true, length: { maximum: 500 }

  def to_model_attributes
    { delivery_address: delivery_address, notes: notes }
  end
end
```

### Presenters

**Own:** Formatting (currency, dates, localization), conditional display logic, computed display values

**MUST NOT own:** Database queries, business logic, mutation

```ruby
class InvoicePresenter
  def initialize(invoice, view_context)
    @invoice = invoice
    @view_context = view_context
  end

  def formatted_total
    @view_context.number_to_currency(@invoice.total_cents / 100.0)
  end

  def status_label
    I18n.t("invoices.status.#{@invoice.status}")
  end

  def status_css_class
    { draft: "badge--gray", sent: "badge--blue", paid: "badge--green" }
      .fetch(@invoice.status.to_sym, "badge--gray")
  end
end
```

### Serializers

**Own:** API response structure, field selection, nested relationships

**MUST NOT own:** Business logic, database access, field computation beyond simple formatting

```ruby
class OrderSerializer
  def initialize(order, include_items: false)
    @order = order
    @include_items = include_items
  end

  def as_json(*)
    payload = {
      id: @order.id,
      type: "order",
      attributes: attributes
    }
    payload[:relationships] = relationships if @include_items
    payload
  end

  private

  def attributes
    {
      status: @order.status,
      total_cents: @order.total_cents,
      created_at: @order.created_at.iso8601
    }
  end

  def relationships
    { items: @order.line_items.map { |li| LineItemSerializer.new(li).as_json } }
  end
end
```

### Concerns (Shared Logic)

**Rules:**
- One responsibility per concern (name must reflect it)
- Layer-specific only (model concerns in `app/models/concerns/`, controller concerns in `app/controllers/concerns/`)
- Never name: `Utilities`, `Helpers`, `Common` (these indicate no design)
- Require at least two consumers; a concern for one class is just a module

---

## Error Handling Architecture

### Domain Error Hierarchy

**All application errors MUST inherit from `ApplicationError`.**

```ruby
# app/errors/application_error.rb
class ApplicationError < StandardError; end

# Domain-specific
class AuthenticationError < ApplicationError; end
class AuthorizationError < ApplicationError; end
class ValidationError < ApplicationError; end
class NotFoundError < ApplicationError; end
class PaymentError < ApplicationError; end
class ExternalServiceError < ApplicationError; end
```

### Where Errors Are Raised vs. Rescued

| Detects | Raises | Rescued By |
|---|---|---|
| Service Object | `PaymentError`, `ValidationError` | Controller's `rescue_from` |
| Query Object | `NotFoundError` | Controller's `rescue_from` |
| Model callback | `ValidationError` | Service object or controller |
| External client | `ExternalServiceError` | Service object (with fallback) |

**RULE:** No intermediate layer may silently swallow an error. Rescue only at the HTTP boundary.

```ruby
class ApplicationController < ActionController::Base
  rescue_from AuthorizationError,   with: :render_forbidden
  rescue_from NotFoundError,        with: :render_not_found
  rescue_from ExternalServiceError, with: :render_unavailable

  private

  def render_forbidden(error)
    Rails.logger.warn(event: "authorization.denied", user_id: current_user&.id)
    render json: { error: "Forbidden" }, status: :forbidden
  end
end
```

> **RULE:** Error responses MUST NOT include stack traces, internal class names, database columns, or implementation details. Log the detail; surface only the category.

---

## Database Architecture

### Migrations: Immutable & Schema-Only

| Rule | Consequence |
|---|---|
| Never edit a merged migration | Create a new migration instead |
| No logic in migrations | Schema changes ONLY: `create_table`, `add_column`, `add_index` |
| No model references | Use anonymous stubs if data access is unavoidable |
| Data changes in separate migrations | Use `data-migrate` gem for seeds and transformations |

```ruby
# ✓ CORRECT: Anonymous stub for data access
class BackfillOrderStatus < ActiveRecord::Migration[7.2]
  class Order < ActiveRecord::Base; end

  def up
    Order.where(status: nil).update_all(status: "draft")
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
```

### Schema Integrity (Database-Level Constraints)

| Constraint | Enforcement |
|---|---|
| Required field | `null: false` in migration |
| Unique field | `add_index :table, :column, unique: true` |
| Foreign key | `add_foreign_key :child, :parent` |
| Default value | `default:` in migration (not model) |
| Enum values | Database check constraint for critical enums |

### Index Coverage (Mandatory)

**Every column in `WHERE`, `ORDER BY`, `JOIN ON`, or `GROUP BY` MUST have an index.**

- Foreign keys: Index automatically with `index: true`
- Status columns: Index all columns used for filtering
- Timestamps: Index any timestamp used in queries
- Compound filters: Compound index in correct column order (most selective first)

---

## Background Jobs Architecture

### The Thin Job Pattern

A job is a scheduling mechanism, not a logic container. **Jobs MUST delegate to service objects immediately. No business logic inside job bodies.**

```ruby
# ✓ CORRECT: Delegates to service
class InvoiceReminderJob < ApplicationJob
  queue_as :mailers

  def perform(invoice_id)
    invoice = Invoice.find_by(id: invoice_id)
    return unless invoice

    InvoiceReminderService.call(invoice)
  end
end

# ✗ WRONG: Business logic and side effects in job
def perform(invoice_id)
  invoice = Invoice.find(invoice_id)
  InvoiceMailer.reminder(invoice).deliver_now
  invoice.update!(reminder_sent_at: Time.current)
end
```

### Idempotency (Critical)

**Every job MUST be safe to execute multiple times with the same arguments.** Jobs are retried automatically — non-idempotent jobs corrupt data under normal conditions.

Patterns (in order of preference):
1. **Database uniqueness constraint** — Let the DB reject the duplicate
2. **Record lock + state check** — `with_lock` and re-check before acting
3. **Idempotency key** — Store a job execution record

### Enqueuing Rules

| Rule | Why |
|---|---|
| Never enqueue inside a transaction | If transaction rolls back, the job is already queued |
| Pass IDs, not objects | Objects become stale; IDs do not |
| `queue_as` explicit | Never rely on default queue |
| `retry_on` and `discard_on` explicit | Define expected retry and failure behavior |

```ruby
class PaymentProcessingJob < ApplicationJob
  queue_as :payments
  retry_on ExternalServiceError, wait: :exponentially_longer, attempts: 5
  discard_on PaymentDeclinedError

  def perform(payment_id)
    PaymentProcessingService.call(Payment.find(payment_id))
  end
end
```

---

## Configuration & Secrets Architecture

### Configuration Categories and Locations

| Category | Example | Location |
|---|---|---|
| Defaults | Default page size, upload limits | `config/application.rb` |
| Environment-specific | Feature flags, log levels | `config/environments/[env].rb` |
| Secrets (encrypted) | API keys, passwords | `config/credentials/[env].yml.enc` |
| Secrets (environment) | Values from deployment platform | `ENV.fetch("KEY")` |
| Third-party | Stripe config, S3 bucket | `config/initializers/[service].rb` |

### `ENV.fetch` Mandate

**`ENV["KEY"]` returns `nil` when missing — silent failures. `ENV.fetch("KEY")` raises at boot.**

```ruby
# ✓ CORRECT: Fails at boot if missing
Stripe.api_key = ENV.fetch("STRIPE_SECRET_KEY")

# ✗ WRONG: Silent nil
Stripe.api_key = ENV["STRIPE_SECRET_KEY"]
```

### Boot-Time Validation

Define a centralizer that validates all required environment variables at boot.

```ruby
# config/initializers/required_env.rb
REQUIRED = %w[STRIPE_SECRET_KEY SENDGRID_API_KEY REDIS_URL DATABASE_URL].freeze
missing = REQUIRED.reject { |key| ENV.key?(key) }

if missing.any?
  raise "Missing environment variables:\n  #{missing.join("\n  ")}"
end
```

---

## API Architecture

### Versioning (Mandatory)

All endpoints MUST be versioned from the first release. Version is expressed in the URL path.

```ruby
# config/routes.rb
namespace :api do
  namespace :v1 do
    resources :orders, only: %i[index show create]
  end
end

# app/controllers/api/v1/orders_controller.rb
```

> **RULE:** New version required when removing, renaming, or changing field types. Adding fields is backward-compatible.

### Response Envelope (Mandatory)

**All responses use consistent envelope. Callers can determine success without inspecting HTTP status alone.**

Success:
```json
{
  "data": {
    "id": 42,
    "type": "order",
    "attributes": { "status": "confirmed", "total_cents": 12500 }
  },
  "meta": { "request_id": "..." }
}
```

Error:
```json
{
  "errors": [
    { "code": "validation_failed", "field": "address", "message": "can't be blank" }
  ],
  "meta": { "request_id": "..." }
}
```

### Serialization (Mandatory)

All API serialization MUST use dedicated serializer classes in `app/serializers/`. Using `to_json` on models is forbidden.

---

## Compliance Checklist

Before any PR, verify ALL of the following:

### Structure
- [ ] New files in correct directory per placement rules
- [ ] No business logic in models, controllers, or `lib/`
- [ ] No queries written inline in controllers or views

### Layers
- [ ] Every service follows Result pattern with class-level `call`
- [ ] Every query returns `ActiveRecord::Relation`, not array
- [ ] Every form uses `ActiveModel::Model` and `to_model_attributes`
- [ ] Every presenter receives view context via constructor
- [ ] No concern named `Utilities`, `Helpers`, or `Common`

### Errors
- [ ] New errors inherit from `ApplicationError` or subclass
- [ ] No rescue without re-raise or logging in services/models
- [ ] New error types handled in `ApplicationController` via `rescue_from`
- [ ] No error response leaks implementation details

### Database
- [ ] Every new column has nullability (`null: false` or documented `null: true`)
- [ ] Every FK has `add_foreign_key` and index
- [ ] Every query column indexed
- [ ] No model classes referenced in migration files
- [ ] Data changes in separate migration, not schema migration

### Jobs & Config
- [ ] Every job delegates to service (no business logic in job)
- [ ] Every job declares `queue_as`, `retry_on`, `discard_on`
- [ ] No job enqueued inside transaction
- [ ] Every env var uses `ENV.fetch`, added to boot-time validation

### API
- [ ] New endpoints under current version namespace
- [ ] All responses use standard envelope
- [ ] All serialization via dedicated serializer class

### Tests
- [ ] Service objects tested: happy path + all failure paths
- [ ] Controller actions tested: success + unauth + invalid input
- [ ] No test uses `sleep`
- [ ] No test relies on data from previous test
- [ ] `bundle audit` passes

---

## Violation Severity

| Level | Examples | Action |
|---|---|---|
| **CRITICAL — Block** | Model calling service, controller with 2+ service calls, query returning array, job with logic, FK without index | Fix before PR review continues |
| **MAJOR — Block** | Concern named `Utilities`, serializer with business logic, FK without `add_foreign_key`, env var with `ENV[]` | Fix before approval |
| **MINOR — Must fix** | Service named `OrderService` not `OrderCreationService`, missing `queue_as` on job | Fix before feature ships |

---

## Key Principles to Remember

✓ **Isolation:** Each component independently understandable and testable  
✓ **Explicitness:** Data flow traceable by reading code  
✓ **Stability:** Business changes confined to one layer  
✓ **Result Pattern:** Services return Results, not raise exceptions for business failures  
✓ **Thin Jobs:** Jobs dispatch; services execute  
✓ **One Responsibility:** Models, controllers, services, queries each own one thing  

If a design violates any of these, it's wrong — regardless of convenience.

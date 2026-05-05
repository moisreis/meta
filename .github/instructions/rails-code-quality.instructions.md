---
description: "Use when writing or reviewing Ruby on Rails code, generating services, models, controllers, helpers, or jobs. Covers correctness, security, modularity, DRY principles, maintainability, and production readiness. Pairs with rails-documentation.instructions.md. NO EXCEPTIONS."
name: "Rails Code Quality Standard"
applyTo: ["**/*.rb", "**/*.html.erb"]
---

# Ruby on Rails Code Quality Standard

**RULE: Code is production-ready only when it is correct, secure, modular, maintainable, and observable. Every rule in this guide is mandatory. No cutting corners.**

---

## 1. Quality & Correctness

Code is correct when it does exactly what it is designed to do, in all cases, including edge cases and failures.

### Explicitness Over Implicitness

- **NO implicit behavior, side effects, or assumed context**
- Every operation must be traceable from the call site
- No reliance on globals like `current_user`; pass dependencies explicitly

```ruby
# ✓ CORRECT: intent and scope are explicit
def publish!(user:)
  raise PublishError, "User lacks permission" unless user.can?(:publish, self)
  update!(status: :published, published_at: Time.current, published_by: user)
end

# ✗ WRONG: relies on global, mutates silently, no guard
def publish
  update(status: :published)
end
```

### No Silent Failures

- **Every failure path MUST be handled explicitly**
- Rescuing `StandardError` without re-raising or logging is forbidden
- Returning `nil` from a method is forbidden unless documented and intentional

```ruby
# ✓ CORRECT: failure path is explicit
def find_invoice(id)
  Invoice.find(id)
rescue ActiveRecord::RecordNotFound => e
  Rails.logger.warn("Invoice #{id} not found: #{e.message}")
  raise InvoiceNotFoundError, "Invoice #{id} does not exist"
end

# ✗ WRONG: swallows exception, returns nil with no explanation
def find_invoice(id)
  Invoice.find(id)
rescue StandardError
  nil
end
```

### No Dead Code

- **Dead code MUST NOT exist:** commented-out blocks, unreachable branches, unused methods, unused variables
- If code is not used, delete it. Version control preserves history

### No Magic Numbers or Strings

- **All unnamed literals with domain meaning MUST be extracted into named constants**
- The name MUST explain the meaning

```ruby
# ✓ CORRECT: meaning is declared
SESSION_EXPIRY_SECONDS = 1_800  # The grace period after which sessions expire
session.last_active_at > SESSION_EXPIRY_SECONDS.seconds.ago

# ✗ WRONG: 1800 has no declared meaning
session.last_active_at > 1800.seconds.ago
```

### Guard Clauses, Not Nested Conditionals

- **Use guard clauses for early returns from invalid states**
- Nesting conditionals beyond two levels is forbidden

```ruby
# ✓ CORRECT: guards, clear flow
def process_refund(order)
  return unless order.refundable?
  return if order.already_refunded?
  RefundService.call(order)
end

# ✗ WRONG: deeply nested, hard to follow
def process_refund(order)
  if order.refundable?
    if !order.already_refunded?
      RefundService.call(order)
    end
  end
end
```

### Test Coverage Requirements (Mandatory)

| Layer | Minimum Tests Required |
|---|---|
| Models | Validations, associations, scopes, every custom method |
| Services | Every public method, every branch, every exception path |
| Controllers | Every action, including auth failures and edge cases |
| Jobs | Happy path, idempotency, failure/retry behavior |
| Helpers & Presenters | Every method with conditional logic |

> **RULE:** A method without a test for its failure path is untested. Tests that only cover the happy path are incomplete.

---

## 2. Safety & Security

**Security is not optional. No security rule may be waived for any reason.**

### Database Queries — No Raw SQL Interpolation

- **String interpolation of user input into SQL is FORBIDDEN**
- Use ActiveRecord query methods or parameterized queries exclusively

```ruby
# ✓ SAFE: ActiveRecord parameterizes values
User.where(email: params[:email])
User.where("created_at > ?", params[:since])

# ✗ SQL INJECTION VECTOR: direct interpolation
User.where("email = '#{params[:email]}'")
```

### Mass Assignment — Strong Parameters Required

- **Every controller action accepting external parameters MUST define a `permit` list**
- `permit!` is forbidden in production code

```ruby
# ✓ CORRECT: explicit permit list
def user_params
  params.require(:user).permit(:name, :email, :role)
end

# ✗ WRONG: permits ALL attributes including :admin, :id, :role
def user_params
  params.require(:user).permit!
end
```

### Authentication & Authorization on Every Endpoint

- **Every controller action MUST verify identity and permission**
- Use `before_action` at the controller level; override only with an inline comment explaining why public access is acceptable

```ruby
class ApplicationController < ActionController::Base
  before_action :require_authenticated_user!
  before_action :authorize_request!
end
```

### Secrets — No Hardcoded Credentials

- **Secrets, API keys, passwords, tokens MUST NOT appear in source code**
- Use Rails credentials (`config/credentials.yml.enc`) or environment variables exclusively
- **RULE:** Use `ENV.fetch("KEY")`, not `ENV["KEY"]` — missing vars raise an error at boot, not silent `nil`

```ruby
# ✓ CORRECT: fetch from environment
Stripe.api_key = ENV.fetch("STRIPE_SECRET_KEY")

# ✗ WRONG: hardcoded secret
Stripe.api_key = "sk_live_abc123xyz"
```

### Input Sanitization at Every Boundary

- **Treat all user-supplied input as hostile:** HTTP params, file uploads, webhooks, job arguments
- HTML output: use Rails helpers (`h`, `sanitize`); never use `.html_safe` without explicit sanitization
- File uploads: validate MIME type by inspecting file content, not client-supplied header
- JSON: validate schema before processing

---

## 3. Modularity & Single Responsibility

**A class has one responsibility. A method has one responsibility. If you cannot describe what a class does without the word "and," it has too many responsibilities.**

### Layer Responsibilities

| Layer | Responsibility | Must NOT Contain |
|---|---|---|
| Model | Data shape, validations, associations, named scopes, data-level computations | Business logic, HTTP concerns, presentation |
| Controller | Receive request, call one service, return response | Business logic, queries, rendering logic |
| Service Object | Orchestrate a single business operation | Unrelated model persistence, HTTP response handling |
| Query Object | Build and execute a single database query | Business logic, presentation |
| Form Object | Validate and coerce multi-model or complex input | Persistence beyond `save` |
| Presenter / Decorator | Format data for display | Business logic, database access |

### Method Length — Maximum 10 Lines

- **No method may exceed 10 lines**
- If a method exceeds 10 lines, it is doing more than one thing
- Extract additional responsibilities into named private methods

> Why: A method that fits on one screen can be understood without scrolling.

### Class Length — Maximum 150 Lines

- **No class may exceed 150 lines (excluding comments and blank lines)**
- If exceeded, the class has too many responsibilities
- Extract into collaborating objects

### Controller Actions — One Service Call

- **A controller action MUST perform at most one substantive operation**
- Call a single service object or model method
- Multiple DB operations or business logic branches = bypassed service layer = refactor required

```ruby
# ✓ CORRECT: delegates to service
def create
  result = OrderCreationService.call(order_params, current_user)
  if result.success?
    redirect_to result.order, notice: "Order placed."
  else
    render :new, status: :unprocessable_entity
  end
end

# ✗ WRONG: business logic in controller
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

---

## 4. DRY — Don't Repeat Yourself

**Duplication is a defect. A bug fixed in one place silently persists in all other copies.**

### The Three-Occurrence Rule

- **Abstraction is mandatory at the third occurrence**
- After the second occurrence, leave a `# TODO: extract if this appears again` comment
- After the third occurrence, extract immediately

### Shared Logic — Concerns

- Logic shared across multiple models/controllers MUST be extracted into a `Concern`
- Each Concern MUST have a single, named responsibility
- Avoid generic names like `Utilities` or `Helpers`

### Shared Views — Partials

- Any view fragment rendered in more than one location MUST be extracted into a partial
- Partials MUST receive data exclusively through local variables
- Instance variables inside partials are forbidden

### Shared Validations

- Validation rules applied to multiple models MUST be extracted into a custom validator class under `app/validators/`
- Never duplicate validation logic across models

### Shared Test Logic

- Test logic repeated across more than two spec files MUST be extracted into RSpec shared examples or shared contexts
- Copy-pasted test setup is a maintenance liability equivalent to copy-pasted production code

---

## 5. Maintainability

Code is maintainable when a developer who did not write it can understand, extend, and safely modify it.

### Naming Rules (Mandatory)

| Rule | Correct | Incorrect |
|---|---|---|
| No abbreviations | `calculate_tax` | `calc_tx` |
| No single-letter vars (except loop indexes) | `user`, `invoice` | `u`, `i` (outside loops) |
| No ambiguous names | `pending_orders` | `data`, `result`, `info`, `stuff` |
| Boolean methods end in `?` | `user.active?` | `user.is_active`, `user.active` |
| Mutating methods end in `!` | `order.cancel!` | `order.cancel` (if it raises/mutates) |
| Methods named for return value | `invoice_total` | `get_invoice_total`, `fetch_total` |

### No Cleverness

- **Code MUST favor clarity over cleverness**
- One-liners that sacrifice readability are forbidden
- A developer should understand any method within 30 seconds

```ruby
# ✓ CORRECT: clear and readable
def discounted_price(price, discount_percent)
  discount = price * (discount_percent / 100.0)
  price - discount
end

# ✗ WRONG: technically correct, not immediately readable
def discounted_price(p, d) = p * (1 - d / 100.0)
```

### Cyclomatic Complexity — Maximum 5

- **No method may have cyclomatic complexity > 5**
- A method with >5 independent logical paths cannot be reliably tested
- Enforce with RuboCop:
  ```yaml
  Metrics/CyclomaticComplexity:
    Max: 5
  ```

### Dependency Injection

- **Classes MUST NOT instantiate their own collaborators**
- Dependencies MUST be injected at construction or passed as method arguments
- Hard-coded instantiation makes a class impossible to test in isolation

```ruby
# ✓ CORRECT: dependency injected
class OrderNotifier
  def initialize(mailer: UserMailer)
    @mailer = mailer
  end

  def notify_confirmation(order)
    @mailer.order_confirmation(order).deliver_later
  end
end

# ✗ WRONG: cannot test without sending real emails
class OrderNotifier
  def notify_confirmation(order)
    UserMailer.order_confirmation(order).deliver_later
  end
end
```

### Changelog Discipline

- **Every pull request MUST include an entry in `CHANGELOG.md`**
- Entries MUST be categorized: `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, `Security`

---

## 6. Documentation & Rationale

### Rationale Comments for Non-Obvious Decisions

- **Every non-obvious decision MUST have an inline comment explaining *why*, not *what***
- What the code does is visible; why it does it that way is not

```ruby
# ✓ CORRECT: explains the why
# We skip callbacks here intentionally: calling `save!` would trigger
# AuditService before the transaction commits, causing race conditions.
# The audit is written manually below inside the transaction.
record.update_columns(status: :archived)

# ✗ WRONG: just describes what, which is obvious
# Updates the record status to archived.
record.update_columns(status: :archived)
```

### Exception Documentation — Recovery Path

- **Every rescued exception MUST have a comment describing the recovery path for callers**

```ruby
# @raise [PaymentDeclinedError] Raised when processor rejects the charge.
#   Callers should display the localized error message and allow the user
#   to re-enter payment information. Do NOT retry automatically.
def charge!(amount)
  # ...
end
```

### Public API Contracts

- **Every method forming a public boundary MUST have a full YARD contract block**
- Service entry points, model scopes consumed externally, serializer methods
- Partial documentation of a public API boundary = no documentation

---

## 7. Production Readiness

Code is production-ready when it operates correctly under real traffic, recovers gracefully, and provides observability.

### Structured Logging

- **Every significant operation MUST emit a structured log entry**
- `puts` and `p` are forbidden in production code
- Log messages MUST include enough context to diagnose without reading source code

```ruby
Rails.logger.info(
  event:         "order.created",
  order_id:      order.id,
  user_id:       current_user.id,
  total_cents:   order.total_cents
)
```

Log severity guidelines:

| Level | When to Use |
|---|---|
| `debug` | Granular tracing during development only |
| `info` | Normal business events (order created, user authenticated) |
| `warn` | Recoverable anomalies (retry attempted, fallback used) |
| `error` | Failures requiring operator attention |
| `fatal` | Application cannot continue — immediate action required |

### Database — Index Coverage

- **Every foreign key MUST have a database index**
- **Every column used in `where`, `order`, or `group` clauses MUST have an index**
- Missing indexes are a correctness defect, not just an optimization concern

Add to CI:
```bash
bundle exec rails db:check_index_coverage
```

### N+1 Elimination

- **Every collection endpoint MUST eagerly load all associations accessed during rendering**
- Use `includes`, `preload`, or `eager_load` as appropriate
- Use the `Bullet` gem in development to detect N+1 queries:
  ```ruby
  config.after_initialize do
    Bullet.enable = true
    Bullet.raise = true  # Raises error — cannot be ignored
  end
  ```

### Pagination on All Collection Endpoints

- **Every controller action returning a collection MUST paginate**
- Returning unbounded collections is forbidden
- Use `pagy` or `kaminari`; define default page size as a constant

```ruby
DEFAULT_PAGE_SIZE = 25

def index
  @orders = Order.all.order(created_at: :desc)
  @pagy, @orders = pagy(@orders, items: DEFAULT_PAGE_SIZE)
end
```

### Background Jobs — Idempotency

- **Every background job MUST be idempotent**
- A job safe to run once but producing incorrect results if retried is NOT production-ready
- Use unique job IDs or database-level locks to guard against double-execution

```ruby
class ProcessPaymentJob < ApplicationJob
  def perform(payment_id)
    payment = Payment.find(payment_id)

    # Guard: already processed — safe to exit
    return if payment.processed?

    payment.with_lock do
      return if payment.processed?  # Re-check inside lock

      PaymentProcessor.charge!(payment)
      payment.update!(status: :processed)
    end
  end
end
```

### Graceful Degradation

- **Non-critical external service calls MUST have a timeout and fallback**
- An unavailable third-party service MUST NOT bring down the application

```ruby
def fetch_shipping_estimate(order)
  ShippingClient.estimate(order)
rescue ShippingClient::TimeoutError, ShippingClient::ServiceUnavailable => e
  Rails.logger.warn(event: "shipping.estimate.fallback", order_id: order.id)
  ShippingEstimate.default  # Safe, pre-configured fallback
end
```

### Environment Configuration

- **All environment-specific values MUST come from the environment**
- Never hardcode values in initializers or committed config files
- Use `ENV.fetch` with a descriptive error so misconfigured deployments fail at boot

```ruby
# config/initializers/stripe.rb
Stripe.api_key = ENV.fetch("STRIPE_SECRET_KEY") do
  raise "STRIPE_SECRET_KEY is not set. Add it to your environment before booting."
end
```

---

## Compliance Checklist

Before submitting any code, verify ALL of the following:

### Step 1 — Quality & Correctness
- [ ] Every failure path is handled explicitly (no silent rescues)
- [ ] No dead code, commented-out logic, or unused variables
- [ ] All magic numbers/strings extracted into named constants
- [ ] No method exceeds 10 lines
- [ ] No conditional nesting exceeds 2 levels
- [ ] Test coverage meets minimums for the layer

### Step 2 — Safety & Security
- [ ] All database queries use parameterized values (no interpolation)
- [ ] All controller actions define a `permit` list (no `permit!`)
- [ ] All endpoints covered by authentication and authorization
- [ ] No secrets, keys, or passwords in source code
- [ ] All user input validated and sanitized at boundaries

### Step 3 — Modularity
- [ ] Each class has one articulable responsibility
- [ ] Business logic in service objects (not models or controllers)
- [ ] Database queries in query objects or named scopes (not inline)
- [ ] No class exceeds 150 lines excluding comments

### Step 4 — DRY
- [ ] No logic duplicated 3+ times without abstraction
- [ ] Shared model/controller logic extracted into Concerns
- [ ] Shared views extracted into partials with local variables only
- [ ] Shared test setup extracted into shared examples or contexts

### Step 5 — Maintainability
- [ ] All names follow naming rules (no abbreviations, no ambiguous names)
- [ ] Cyclomatic complexity within limit (RuboCop passes)
- [ ] All collaborators injected (no hard-coded instantiation)
- [ ] `CHANGELOG.md` updated with categorized entry

### Step 6 — Production Readiness
- [ ] All significant operations emit structured log entries
- [ ] All new foreign keys and query columns indexed
- [ ] All collection endpoints paginate results
- [ ] All new background jobs idempotent and guarded
- [ ] All external service calls have timeout and fallback
- [ ] All environment variables use `ENV.fetch`

---

## Violation Severity

| Severity | Examples | Action |
|---|---|---|
| **CRITICAL — Block** | SQL injection, missing auth, hardcoded secret, swallowed exception | Fix before PR review continues |
| **MAJOR — Block** | No tests, methods >10 lines with logic, missing pagination, no indexes | Fix before approval |
| **MINOR — Must fix** | Abbreviation in name, missing CHANGELOG, no rationale comment | Resolve before feature ships |

---

## Related Standards

- **Documentation:** See `rails-documentation.instructions.md` for YARD, TOCs, section dividers, and view documentation
- **Complete Reference:** See `Code quality standard.md` in project documentation for detailed examples and rationale

---

## Quick Checklist Before Commit

1. ✓ Correctness: Every failure path handled explicitly?
2. ✓ Security: Queries parameterized, auth on all endpoints, no secrets in code?
3. ✓ Modularity: Each class one responsibility, service layer used?
4. ✓ DRY: No 3+ logic duplications, shared logic abstracted?
5. ✓ Maintainability: Names clear, RuboCop passes, dependencies injected?
6. ✓ Production: Logging, indexes, pagination, idempotency, fallbacks?

If **any answer is NO**, the code is not production-ready. Fix it before submitting.

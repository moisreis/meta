---
description: "Use when writing or reviewing Ruby on Rails code, generating Ruby classes, methods, models, controllers, services, helpers, or ERB templates. Covers YARD documentation, schema blocks, TOC, section dividers, and view documentation standards. NO EXCEPTIONS."
name: "Rails Documentation Standard"
applyTo: ["**/*.rb", "**/*.html.erb"]
---

# Ruby on Rails Documentation Standard

**RULE: Every class, method, and file MUST have documentation. No exceptions. When in doubt, document more — not less.**

---

## Ruby Files (`.rb`)

### Classes & Modules

**REQUIRED for every class/module:**
1. **Single-sentence summary** (first line) — describe the class's primary responsibility
2. **Longer description** — explain architectural role if non-obvious; reference related classes using `{ClassName}`
3. **`@author` tag** — always include
4. **`@abstract` tag** — if meant to be subclassed

```ruby
# Handles the interface between the internal Order system and external
# payment processors (Stripe, PayPal).
#
# This class is responsible only for communication with the processor.
# It does NOT handle order state — that belongs to {OrderService}.
#
# @author Project Team
# @abstract Subclass and override {#process_payment} to implement a gateway.
class PaymentGateway
  # ...
end
```

### Methods (Public & Protected)

**REQUIRED for every public/protected method:**
- `@param` — for each argument; include **type**, **name**, **description**
- `@option` — for each key in a `Hash` parameter
- `@return` — type and description of return value
- `@raise` — each exception this method can raise, and why

```ruby
# Validates the credit card and creates a transaction record.
#
# @param amount [Integer] The charge amount in cents (e.g., 1000 = $10.00).
# @param card_token [String] The tokenized card data received from the frontend.
# @param options [Hash] Optional metadata for the transaction.
# @option options [String] :description A brief note that appears on the statement.
# @option options [String] :currency ISO 4217 currency code (default: "USD").
#
# @return [Transaction] The persisted transaction object on success.
# @raise [PaymentError] If the processor declines the card or is unreachable.
def authorize(amount, card_token, options = {})
  # implementation
end
```

### Private Methods

**MINIMUM:** One-line description. Full `@param`/`@return` tags strongly encouraged unless trivially self-evident.

### Constants & Attributes

Document all non-obvious constants and `attr_*` declarations:

```ruby
# @!attribute [r] status
#   @return [Symbol] The current state (:pending, :authorized, :failed).
attr_reader :status

# Maximum number of retry attempts before raising {PaymentError}.
MAX_RETRIES = 3
```

### File Table of Contents (TOC)

**REQUIRED for every non-trivial Ruby file.** Place in the class header block, at the bottom, separated by a blank comment line.

**Rules:**
- Top-level: `1.`, `2.`, `3.`… (numbered)
- Subsections: `3a.`, `3b.`… (parent number + lowercase letter)
- Indent subsections two spaces
- Align in a single column (no right-padding)

```ruby
# [Class summary and @author tags above]
#
# TABLE OF CONTENTS:
#   1.  Constants & Configuration
#   2.  Initialization
#   3.  Public Methods
#       3a. Authorization
#       3b. Capture & Refund
#   4.  Private Methods
#       4a. Request Helpers
#       4b. Error Handling
#
# @author Project Team
class PaymentGateway
```

### Section Dividers

**REQUIRED: Every TOC entry MUST have a matching divider banner in the file body.**

Format: Three lines
- Line 1: `# ` + 61 `=` characters (63 total)
- Line 2: `# ` + **centred** section identifier + name in ALL CAPS
- Line 3: `# ` + 61 `=` characters

```ruby
# =============================================================
#                     1. CONSTANTS & CONFIGURATION
# =============================================================

MAX_RETRIES = 3

# =============================================================
#                        3a. AUTHORIZATION
# =============================================================

# Validates the credit card...
# @param amount [Integer] ...
def authorize(amount, card_token)
```

---

## View Files (`.html.erb`)

### Partials

**REQUIRED header block at the top of every partial:**

```erb
<%#
  PARTIAL: app/views/[path/to]/_partial_name.html.erb
  DESCRIPTION: [One sentence describing what this renders.]

  LOCAL VARIABLES:
  - variable_name: [Type] Description. (required)
  - variable_name: [Type] Description. (default: value)
%>
```

**Example:**

```erb
<%#
  PARTIAL: app/views/users/_user_card.html.erb
  DESCRIPTION: Displays a summarized user profile card with optional avatar.

  LOCAL VARIABLES:
  - user:         [User]    The User record to display. (required)
  - show_avatar:  [Boolean] Whether to render the profile image. (default: true)
  - highlight:    [Boolean] Adds a highlight border for premium members. (default: false)
%>

<div class="user-card <%= 'highlight' if local_assigns[:highlight] %>">
  ...
</div>
```

### Full View Templates

Add a header block describing the action and instance variables:

```erb
<%#
  VIEW: app/views/orders/show.html.erb
  ACTION: OrdersController#show

  INSTANCE VARIABLES:
  - @order: [Order] The order being displayed, with :line_items eager-loaded.
  - @refund_policy: [String] Localized refund policy text.
%>
```

### ERB Table of Contents

**REQUIRED if 3+ distinct rendering regions.**

Place at the bottom of the header block, after `LOCAL VARIABLES` or `INSTANCE VARIABLES`.

```erb
<%#
  PARTIAL: app/views/orders/_order_summary.html.erb
  ...

  TABLE OF CONTENTS:
  1.  Header — Order Number & Status Badge
  2.  Line Items Table
  3.  Footer
      3a. Subtotal & Tax
      3b. Refund Policy Note
%>
```

### ERB Section Dividers

**REQUIRED: Every TOC entry MUST have a matching divider in the template body.**

Format: Three ERB comment lines
- Line 1: `<%# ` + 57 `=` characters + ` %>`
- Line 2: `<%# ` + **centred** section identifier + name + ` %>`
- Line 3: `<%# ` + 57 `=` characters + ` %>`

```erb
<%# ========================================================= %>
<%#                 1. HEADER — ORDER NUMBER                  %>
<%# ========================================================= %>

<div class="order-header">
  <h1>Order #<%= order.number %></h1>
</div>

<%# ========================================================= %>
<%#                   2. LINE ITEMS TABLE                     %>
<%# ========================================================= %>

<table class="line-items">
  ...
</table>
```

> **RULE:** Use `<%# %>` comments, never `<!-- -->`. HTML comments are visible in rendered source.

---

## Models: Automated Schema

**REQUIRED:** Run `bundle exec annotate --models` to generate schema blocks. Never manually document columns.

```ruby
# == Schema Information
#
# Table name: users
#
#  id        :bigint           not null, primary key
#  email     :string           not null
#  username  :string           not null
#
class User < ApplicationRecord
  # Custom methods and associations here
end
```

> Add inline comments only for non-obvious columns:
> ```ruby
> #  score   :integer          # Normalized 0–100 engagement score.
> ```

---

## Compliance Checklist

Before committing any code, verify:

- [ ] Every class has YARD header with description + `@author`
- [ ] Every public method has `@param`, `@return`, `@raise` (where applicable)
- [ ] Every non-trivial `.rb` file has FILE TABLE OF CONTENTS in the class header
- [ ] Every TOC entry has a matching section divider banner in the file body
- [ ] Every partial has the `LOCAL VARIABLES` Interface Comment block
- [ ] Every full view has the `INSTANCE VARIABLES` block
- [ ] Every ERB file with 3+ regions has TABLE OF CONTENTS + matching dividers
- [ ] All models have annotated schema blocks (run `annotate --models`)

If **any answer is NO**, the code is incomplete. Fix it before submitting.

---

## YARD Tag Summary (Quick Reference)

```ruby
# @param name [Type] Description of the argument.
# @option options [Type] :key Description of the hash key.
# @return [Type] Description of what is returned.
# @raise [ExceptionClass] Condition that triggers this exception.
# @author Name or Team
# @abstract Brief note about subclassing intent.
# @deprecated Use {#new_method} instead.
# @see OtherClass#some_method
# @!attribute [r] name
#   @return [Type] Description.
```

---

## Why This Matters

- **Navigability:** TOCs and dividers let any developer orient instantly without scrolling
- **AI tooling:** Copilot and documentation generators depend on structured metadata
- **Maintenance:** Future changes are safer when intent is explicit
- **Onboarding:** New team members understand architecture faster
- **Compliance:** Enforced via CI/CD — missing docs block merges

---

## Related Documentation

See the full standard in `Documentation standard.md` for detailed examples and rationale.

# Ruby Documentation Standards - Meta Investimentos

## Quick Reference Template

Copy this structure and adapt it to any `.rb` file:

```ruby
# frozen_string_literal: true

# == ClassName or ModuleName
#
# @author Moisés Reis
# @project Meta Investimentos
# @added MM/DD/YYYY
# @package Meta
# @category CategoryName
#
# @description
#   One or two sentences explaining what this class/module does and why it exists.
#   Use present tense. Be specific about its role in the application.
#
# @example Basic usage
#   MyClass.new.do_something
#   # => expected_result
#
# @see RelatedClass or RelatedMethod
#
class ClassName
  # ...
end
```

***

## 1. File Header (Top of Every File)

### Required Tags

| Tag | Format | Description |
|-----|--------|-------------|
| `# frozen_string_literal: true` | First line | Enables frozen string literal optimization |
| `# == ClassName` | Second line | The class or module name being documented |
| `@author` | `Moisés Reis` | Always this value |
| `@project` | `Meta Investimentos` | Always this value |
| `@added` | `MM/DD/YYYY` | Date the file was originally created |
| `@package` | `Meta` | Always this value |
| `@category` | See categories below | The role this file plays |
| `@description` | Paragraph | What this file does and why |
| `@example` | Code block | How to use it (optional for simple files) |
| `@see` | References | Related classes, modules, or methods |

### Category Values by File Type

| File Type | Category |
|-----------|----------|
| Models | `Model` |
| Controllers | `Controller` |
| Helpers | `Helper` |
| Services | `Service` |
| Jobs | `Background Job` |
| Mailers | `Mailer` |
| Concerns | `Concern` |

***

## 2. Method Documentation

### Structure

```ruby
# == method_name
#
# @author Moisés Reis
# @project Meta Investimentos
# @category CategoryName
#
# @description
#   What this method does. Use present tense. Explain the purpose,
#   not the implementation. Keep it to 2-3 sentences.
#
# @param param_name [Type] Description of the parameter
# @param optional_param [Type] Description (default: value)
# @return [Type] What this method returns
#
# @example With description
#   method_name("argument")
#   # => "result"
#
# @example Edge case
#   method_name(nil)
#   # => nil
#
# @see #related_method
# @see RelatedClass
#
def method_name(param_name, optional_param: "value")
  # implementation
end
```

### Required Tags for Methods

| Tag | Format | Required? |
|-----|--------|-----------|
| `# == method_name` | Method name | Yes |
| `@author` | `Moisés Reis` | Yes |
| `@project` | `Meta Investimentos` | Yes |
| `@category` | See method categories below | Yes |
| `@description` | Paragraph | Yes |
| `@param` | `name [Type] description` | Yes, if method has params |
| `@return` | `[Type] description` | Yes |
| `@example` | Code block | Yes, at least one |
| `@see` | References | When applicable |

### Method Category Values

| Category | When to Use |
|----------|-------------|
| `Read` | Query methods, getters, data retrieval |
| `Write` | Create, update, delete operations |
| `Validation` | Methods that check or validate data |
| `Formatting` | Methods that format strings, numbers, dates |
| `UI Helper` | Methods that generate HTML or CSS classes |
| `Color Helper` | Methods related to color calculations |
| `Table Helper` | Methods for table rendering/sorting |
| `Business Logic` | Core domain logic methods |
| `Callback` | `before_save`, `after_create`, etc. |
| `Scope` | ActiveRecord query scopes |
| `Association` | `has_many`, `belongs_to` definitions with blocks |

### Parameter Types

Use these type annotations in `@param` and `@return`:

| Type | Usage |
|------|-------|
| `String` | Text values |
| `Integer` | Whole numbers |
| `Numeric` | Any number (Integer or Float) |
| `Float` | Decimal numbers |
| `Boolean` | true/false |
| `Array<Type>` | Array of specific type |
| `Hash<Symbol, String>` | Hash with symbol keys and string values |
| `Symbol` | Ruby symbols |
| `Date` | Date objects |
| `DateTime` | DateTime objects |
| `Time` | Time objects |
| `Proc` | Lambda or proc |
| `ActiveRecord::Relation` | Database query results |
| `nil` | Nil value |
| `Object` | Any type |

***

## 3. Constant Documentation

```ruby
# == CONSTANT_NAME
#
# @author Moisés Reis
# @project Meta Investimentos
# @category Constants
#
# @description
#   What this constant represents and how it's used.
#
# @return [Type] The type of the constant
#
# @example Usage
#   CONSTANT_NAME[:key]
#   # => "value"
#
# @note Important caveat or warning about this constant
#
CONSTANT_NAME = { key: "value" }.freeze
```

***

## 4. Class/Module Body Documentation

### Instance Variables

```ruby
# @!attribute [r] attribute_name
#   @return [Type] Description of the attribute
attr_reader :attribute_name
```

### Associations (Models)

```ruby
# @!method association_name
#   @return [AssociationType] Description of the association
has_many :association_name
```

### Scopes

```ruby
# == scope_name
#
# @author Moisés Reis
# @project Meta Investimentos
# @category Scope
#
# @description
#   What this scope filters and when to use it.
#
# @return [ActiveRecord::Relation] Filtered records
#
# @example Usage
#   Model.scope_name
#   # => #<ActiveRecord::Relation [...]>
#
scope :scope_name, -> { where(condition: true) }
```

### Callbacks

```ruby
# == callback_method_name
#
# @author Moisés Reis
# @project Meta Investimentos
# @category Callback
#
# @description
#   What this callback does and when it runs (before_save, after_create, etc.).
#
# @return [void]
#
def callback_method_name
  # implementation
end
```

***

## 5. File-Type Specific Guidelines

### Models (`app/models/`)

```ruby
# frozen_string_literal: true

# == ModelName
#
# @author Moisés Reis
# @project Meta Investimentos
# @added MM/DD/YYYY
# @package Meta
# @category Model
#
# @description
#   What this model represents in the domain. Mention its database table,
#   its relationships, and its primary responsibility.
#
# @example Creating a record
#   ModelName.create(attribute: "value")
#
# @example Querying
#   ModelName.active.where(condition: true)
#
# @see RelatedModel
#
class ModelName < ApplicationRecord
  # == Associations ==========================================================

  # @!method related_models
  #   @return [HasMany] Description of the relationship
  has_many :related_models

  # == Validations ===========================================================

  # @!attribute [r] attribute_name
  #   @return [Type] Description
  validates :attribute_name, presence: true

  # == Scopes ================================================================

  # == Callbacks =============================================================

  # == Public Methods ========================================================

  # == Private Methods =======================================================
end
```

### Controllers (`app/controllers/`)

```ruby
# frozen_string_literal: true

# == ControllerNameController
#
# @author Moisés Reis
# @project Meta Investimentos
# @added MM/DD/YYYY
# @package Meta
# @category Controller
#
# @description
#   What resource this controller manages and what actions it exposes.
#   Mention authentication requirements if any.
#
# @see ModelName
#
class ControllerNameController < ApplicationController
  # == Actions ===============================================================

  # == index
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Read
  #
  # @description
  #   What this action does, what it renders, and what parameters it accepts.
  #
  # @return [void] Renders the index view
  #
  def index
  end
end
```

### Helpers (`app/helpers/`)

```ruby
# frozen_string_literal: true

# == HelperName
#
# @author Moisés Reis
# @project Meta Investimentos
# @added MM/DD/YYYY
# @package Meta
# @category Helper
#
# @description
#   What utility methods this helper provides and what views use them.
#
# @example Usage in a view
#   <%= helper_method("argument") %>
#
module HelperName
  # == method_name
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category UI Helper
  #
  # @description
  #   What this helper method does in the view context.
  #
  # @param arg [Type] Description
  # @return [String] HTML string or formatted value
  #
  # @example
  #   helper_method("value")
  #   # => "<span>value</span>"
  #
  def method_name(arg)
  end
end
```

### Services (`app/services/`)

```ruby
# frozen_string_literal: true

# == ServiceName
#
# @author Moisés Reis
# @project Meta Investimentos
# @added MM/DD/YYYY
# @package Meta
# @category Service
#
# @description
#   What business logic this service encapsulates and why it was extracted
#   from a model or controller.
#
# @example Basic usage
#   ServiceName.call(param: "value")
#
# @example With error handling
#   result = ServiceName.call(param: "value")
#   result.success? # => true
#
class ServiceName
  # == call
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Business Logic
  #
  # @description
  #   What this method orchestrates.
  #
  # @param param [Type] Description
  # @return [ResultType] Description
  #
  def self.call(param:)
    new(param: param).call
  end
end
```

### Jobs (`app/jobs/`)

```ruby
# frozen_string_literal: true

# == JobName
#
# @author Moisés Reis
# @project Meta Investimentos
# @added MM/DD/YYYY
# @package Meta
# @category Background Job
#
# @description
#   What this background job does, when it's triggered, and what queue it uses.
#
# @example Enqueueing
#   JobName.perform_later(arg1, arg2)
#
class JobName < ApplicationJob
  # == perform
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Business Logic
  #
  # @description
  #   What this job executes asynchronously.
  #
  # @param arg1 [Type] Description
  # @return [void]
  #
  def perform(arg1, arg2)
  end
end
```

### Mailers (`app/mailers/`)

```ruby
# frozen_string_literal: true

# == MailerName
#
# @author Moisés Reis
# @project Meta Investimentos
# @added MM/DD/YYYY
# @package Meta
# @category Mailer
#
# @description
#   What emails this mailer sends and when they are triggered.
#
class MailerName < ApplicationMailer
  # == email_method
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Write
  #
  # @description
  #   What this email contains and who receives it.
  #
  # @param user [User] The recipient
  # @return [Mail::Message] The composed email
  #
  def email_method(user)
    @user = user
    mail(to: user.email, subject: "Subject")
  end
end
```

***

## 6. Cross-Referencing

Use `@see` to link related code:

```ruby
# @see #method_name          Same class method
# @see ClassName             Another class
# @see ClassName#method      Method in another class
# @see RelatedModel          Related model
```

Use `{#method_name}` inline for references in descriptions:

```ruby
# @description
#   Formats a value using {#currency_format} and applies coloring
#   via {#sign_color_class}.
```

***

## 7. Inline Comments

Use sparingly. Only explain **why**, not **what**:

```ruby
# Good: explains why
return 50 if value.to_f <= 0  # Avoids unnecessary calculations for non-positive values

# Bad: explains what (obvious from code)
# Sets x to 50
x = 50
```

---

## 8. Formatting Rules

| Rule | Example |
|------|---------|
| Use 2-space indentation | Consistent with Ruby style |
| Blank line after `@description` | Separates tag from content |
| One blank line between methods | Separates documentation blocks |
| `# == method_name` has no space after `==` | Consistent with existing style |
| `@param` and `@return` on separate lines | Readability |
| `@example` blocks show input and output | Use `# =>` for results |
| Frozen string literal on line 1 | Always first line |
| `.freeze` on constants | Prevents mutation |

---

## 9. Checklist Before Committing

- [ ] `# frozen_string_literal: true` on line 1
- [ ] File header with all required tags
- [ ] Every public method has `@description`, `@param`, `@return`, `@example`
- [ ] Constants documented with `@return` and `@example`
- [ ] `@author` is `Moisés Reis`
- [ ] `@project` is `Meta Investimentos`
- [ ] `@package` is `Meta`
- [ ] Cross-references added where applicable
- [ ] No inline comments explaining obvious code
- [ ] Consistent 2-space indentation

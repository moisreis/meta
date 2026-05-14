# Handles user creation and update form validation and transformation logic.
#
# This form object encapsulates user input validation rules and provides a
# normalized interface for converting form data into model-compatible attributes.
#
# @author Moisés Reis

class UserForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  # ============================================================================
  # MODEL NAMING OVERRIDE
  # ============================================================================

  # Forces Rails to treat this form object as a `User` model for routing,
  # form builders, and parameter key inference.
  #
  # @return [ActiveModel::Name]
  def self.model_name
    ActiveModel::Name.new(self, nil, "User")
  end

  # ============================================================================
  # ATTRIBUTES
  # ============================================================================

  attribute :first_name, :string
  attribute :last_name,  :string
  attribute :email,      :string
  attribute :role,       :string
  attribute :password,   :string
  attribute :password_confirmation, :string
  attribute :role, :string, default: "user"

  # ============================================================================
  # VALIDATIONS
  # ============================================================================

  validates :first_name, presence: true, length: { minimum: 2, maximum: 50 }
  validates :last_name,  presence: true, length: { minimum: 2, maximum: 50 }
  validates :email,      presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :role,       inclusion: { in: %w[user admin] }
  validate  :passwords_match, if: -> { password.present? }

  # ============================================================================
  # TRANSFORMATION METHODS
  # ============================================================================

  # Converts form data into attributes compatible with the User model.
  #
  # @return [Hash] Normalized attribute hash for persistence.
  def to_model_attributes
    attrs = { first_name:, last_name:, email:, role: }
    attrs.merge!(password:, password_confirmation:) if password.present?
    attrs
  end

  # Builds a form instance from an existing User record.
  #
  # @param user [User] Source user record.
  # @return [UserForm]
  def self.from_user(user)
    new(user.attributes.slice("first_name", "last_name", "email", "role"))
  end

  # ============================================================================
  # PRIVATE METHODS
  # ============================================================================

  private

  # Validates password confirmation consistency.
  #
  # @return [void]
  def passwords_match
    errors.add(:password_confirmation, "não confere") if password != password_confirmation
  end
end

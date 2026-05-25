# frozen_string_literal: true

# Form object responsible for validating and normalizing user
# input data before persistence.
#
# Encapsulates attribute coercion, validation rules, avatar
# attachment handling, and password confirmation logic used by
# service objects.
#
# @author Moisés Reis
#
# ATTRIBUTE GROUPS:
#   - Personal Information
#   - Account Credentials
#   - Avatar

class UserForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  # =============================================================
  #                          MODEL NAME
  # =============================================================

  # Forces Rails to treat this form object as a `User` model for routing,
  # form builders, and parameter key inference.
  #
  # @return [ActiveModel::Name]
  def self.model_name
    ActiveModel::Name.new(self, nil, "User")
  end

  # =============================================================
  #                          ATTRIBUTES
  # =============================================================

  attribute :first_name, :string
  attribute :last_name,  :string
  attribute :email,      :string
  attribute :role,       :string, default: "user"
  attribute :password,              :string
  attribute :password_confirmation, :string

  # Tracks whether role was explicitly assigned rather than defaulted.
  #
  # @return [Boolean]
  attr_reader :role_explicitly_set

  # Overrides the default writer to record that role was explicitly provided.
  #
  # @param value [String] The role value being assigned.
  # @return [void]
  def role=(value)
    @role_explicitly_set = true
    super
  end

  # Uploaded user avatar attachment.
  #
  # Accepts an ActionDispatch::Http::UploadedFile on create/update, or an
  # ActiveStorage::Attached::One when hydrated from an existing User record
  # via {.from_user}.
  #
  # @return [ActionDispatch::Http::UploadedFile, ActiveStorage::Attached::One, nil]
  attr_accessor :avatar

  # =============================================================
  #                          VALIDATIONS
  # =============================================================

  validates :first_name,
            presence: true,
            length: { minimum: 2, maximum: 50 }

  validates :last_name,
            presence: true,
            length: { minimum: 2, maximum: 50 }

  validates :email,
            presence: true,
            format: { with: URI::MailTo::EMAIL_REGEXP }

  validates :role,
            inclusion: { in: %w[user admin] }

  validate :passwords_match,
           if: -> { password.present? }

  # =============================================================
  #                      TRANSFORMATION METHODS
  # =============================================================

  # Converts form data into attributes compatible with the User model.
  #
  # Password attributes are included only when explicitly provided.
  # Avatar is included only when a new file upload is present — an
  # ActiveStorage::Attached::One reference (from {.from_user}) is excluded
  # to avoid re-assigning the already-persisted attachment on updates where
  # no new file was chosen.
  # Role is included only when explicitly set via {#role=}, preventing the
  # default value ("user") from silently overwriting a persisted admin role
  # on updates that go through a form with no role field.
  #
  # @return [Hash] Normalized attribute hash for persistence.
  def to_model_attributes
    attrs = {
      first_name:,
      last_name:,
      email:
    }

    attrs[:role]   = role   if role_changed?
    attrs[:avatar] = avatar if new_avatar?

    attrs.merge!(
      password:,
      password_confirmation:
    ) if password.present?

    attrs
  end

  # Builds a form instance from an existing User record.
  #
  # Preserves the currently attached avatar reference so edit forms can
  # render the existing image without triggering a re-upload.
  #
  # @param user [User] Source user record.
  # @return [UserForm] Hydrated form object instance.
  def self.from_user(user)
    new(
      first_name: user.first_name,
      last_name:  user.last_name,
      email:      user.email,
      role:       user.role,
      avatar:     user.avatar
    )
  end

  # =============================================================
  #                         PRIVATE METHODS
  # =============================================================

  private

  # Returns true only when avatar holds a freshly uploaded file, not an
  # already-persisted ActiveStorage::Attached::One reference.
  #
  # @return [Boolean]
  def new_avatar?
    avatar.present? && !avatar.is_a?(ActiveStorage::Attached::One)
  end

  # Returns true only when role was explicitly assigned via {#role=},
  # distinguishing a deliberate change from the attribute default.
  #
  # @return [Boolean]
  def role_changed?
    @role_explicitly_set == true
  end

  # Validates password confirmation consistency.
  #
  # @return [void]
  def passwords_match
    return if password == password_confirmation

    errors.add(:password_confirmation, "não confere")
  end
end
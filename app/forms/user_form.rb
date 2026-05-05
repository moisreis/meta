# app/forms/user_form.rb
class UserForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  # Tell Rails to use 'user' as the param key and route helper base,
  # instead of inferring 'user_form' from the class name.
  def self.model_name
    ActiveModel::Name.new(self, nil, "User")
  end

  attribute :first_name, :string
  attribute :last_name,  :string
  attribute :email,      :string
  attribute :role,       :string
  attribute :password,   :string
  attribute :password_confirmation, :string
  attribute :role, :string, default: "user"

  validates :first_name, presence: true, length: { minimum: 2, maximum: 50 }
  validates :last_name,  presence: true, length: { minimum: 2, maximum: 50 }
  validates :email,      presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :role,       inclusion: { in: %w[user admin] }
  validate  :passwords_match, if: -> { password.present? }

  def to_model_attributes
    attrs = { first_name:, last_name:, email:, role: }
    attrs.merge!(password:, password_confirmation:) if password.present?
    attrs
  end

  def self.from_user(user)
  new(user.attributes.slice("first_name", "last_name", "email", "role"))
end

  private

  def passwords_match
    errors.add(:password_confirmation, "não confere") if password != password_confirmation
  end
end
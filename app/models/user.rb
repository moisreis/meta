# === user
#
# @author Moisés Reis
# @added 11/25/2025
# @package *Meta*
# @description This class defines the application's user, managing all aspects of authentication,
#              authorization, and ownership of investment **Portfolio** records.
#              It integrates security features using the **Devise** gem.
# @category *Model*
#
# Usage:: - *[What]* This code block represents application users and handles their secure authentication and personal data integrity.
#         - *[How]* It uses **Devise** to manage passwords, sessions, and recovery, while enforcing data rules through validations and associations.
#         - *[Why]* The application needs this class to ensure secure user management, consistent data storage, and strict access control for all financial features.
#
# Attributes:: - *email* @string - The user’s unique email address used for logging in.
#              - *first_name* @string - The user’s given name.
#              - *last_name* @string - The user’s family name.
#              - *role* @enum - Defines the user’s access level (either *user* or *admin*).
#
class User < ApplicationRecord

  # Explanation:: This macro integrates **Devise** modules to handle user authentication,
  #               including secure password hashing, session management, and password recovery.
  devise :database_authenticatable,
         :registerable,
         :recoverable,
         :rememberable,
         :validatable,
         :trackable

  # Explanation:: This establishes a one-to-many relationship, linking the **User** to all
  #               **Portfolio** records they own, and ensures they are destroyed if the user is deleted.
  has_many :portfolios, dependent: :destroy

  # Explanation:: This establishes a one-to-many relationship, tracking explicit access
  #               rules that the user has granted to others or has received from others.
  has_many :user_portfolio_permissions, dependent: :destroy

  # Explanation:: This establishes a through-relationship that collects all **Portfolio** records
  #               the **User** can access, including those they own and those shared via permissions.
  has_many :accessible_portfolios, through: :user_portfolio_permissions, source: :portfolio

  # Explanation:: This validates that the email address is present and must be unique,
  #               ignoring case sensitivity during the uniqueness check.
  validates :email, presence: true, uniqueness: { case_sensitive: false }

  # Explanation:: This validates that the user's first name is present and has
  #               a minimum length of 2 and a maximum length of 50 characters.
  validates :first_name, presence: true, length: {
    minimum: 2,
    maximum: 50
  }

  # Explanation:: This validates that the user's last name is present and has
  #               a minimum length of 2 and a maximum length of 50 characters.
  validates :last_name, presence: true, length: {
    minimum: 2,
    maximum: 50
  }

  # Explanation:: This defines the possible roles a user can hold within the application,
  #               which are used for feature access control and authorization logic.
  enum :role, {
    user: 'user',
    admin: 'admin'
  }

  # == full_name
  #
  # @author Moisés Reis
  # @category *Helper*
  #
  # Helper:: This method dynamically creates a single string by combining the user's first name and last name.
  #          It is used to display the user's name clearly across the application interface.
  #
  def full_name
    "#{first_name} #{last_name}".strip
  end

  # == ransackable_attributes
  #
  # @author Moisés Reis
  # @category *Query*
  #
  # Query:: This method defines which columns of the **User** model are allowed to be searched or filtered by users through advanced query tools like Ransack.
  #         It ensures only safe and relevant fields are exposed.
  #
  def self.ransackable_attributes(auth_object = nil)
    [
      "created_at",
      "current_sign_in_at",
      "current_sign_in_ip",
      "email",
      "encrypted_password",
      "first_name",
      "id",
      "id_value",
      "last_name",
      "last_sign_in_at",
      "last_sign_in_ip",
      "remember_created_at",
      "reset_password_sent_at",
      "reset_password_token",
      "role",
      "sign_in_count",
      "updated_at"
    ]
  end

  # == ransackable_associations
  #
  # @author Moisés Reis
  # @category *Query*
  #
  # Query:: This method lists the associated models (relationships) of the **User** that advanced query tools like Ransack can join for searching.
  #         It limits available joins to portfolio-related connections.
  #
  def self.ransackable_associations(auth_object = nil)
    [
      "accessible_portfolios",
      "portfolios",
      "user_portfolio_permissions"
    ]
  end
end
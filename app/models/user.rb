# === user
#
# @author Moisés Reis
# @added 11/11/2025
# @package *Auth*
# @description Defines the **User** model, which manages authentication, authorization, and
#              associations with portfolios. It integrates **Devise** modules to handle secure
#              login, registration, and user session management. It also manages user roles
#              and validates essential profile information.
# @category *Model*
#
# Usage:: - *[what]* represents application users and handles their authentication and data integrity
#         - *[how]* integrates **Devise** modules, enforces validations, defines associations, and provides helper methods for displaying user information
#         - *[why]* ensures secure user management, data consistency, and access control across the app
#
# Attributes:: - *[:email]* @string - user’s unique email address used for authentication
#              - *[:first_name]* @string - user’s first name
#              - *[:last_name]* @string - user’s last name
#              - *[:role]* @enum - defines user’s access level (either *user* or *admin*)
#
class User < ApplicationRecord

  # [Devise modules] Provides authentication, registration, recovery, and security features.
  devise :database_authenticatable,
         :registerable,
         :recoverable,
         :rememberable,
         :validatable,
         :trackable

  # [Associations] Connects user to owned and accessible portfolios and related report logs.
  has_many :portfolios, dependent: :destroy
  has_many :user_portfolio_permissions, dependent: :destroy
  has_many :accessible_portfolios, through: :user_portfolio_permissions, source: :portfolio

  # [Validations] Ensures essential user data is present and correctly formatted.
  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :first_name, presence: true, length: { minimum: 2, maximum: 50 }
  validates :last_name, presence: true, length: { minimum: 2, maximum: 50 }

  # [Enumerations] Defines user roles for access control logic.
  enum :role, { user: 'user', admin: 'admin' }

  # [Method] Returns the user's full name in a readable format.
  def full_name
    "#{first_name} #{last_name}".strip
  end

  # [Method] Lists the attributes that Ransack allows for searching and filtering.
  #          Restricts queries to safe fields that represent user identity and activity.
  def self.ransackable_attributes(auth_object = nil)
    [
      "created_at", "current_sign_in_at", "current_sign_in_ip", "email",
      "encrypted_password", "first_name", "id", "id_value", "last_name",
      "last_sign_in_at", "last_sign_in_ip", "remember_created_at",
      "reset_password_sent_at", "reset_password_token", "role",
      "sign_in_count", "updated_at"
    ]
  end

  # [Method] Lists the associations that Ransack allows for relational querying.
  #          Limits available joins to portfolio-related connections.
  def self.ransackable_associations(auth_object = nil)
    ["accessible_portfolios", "portfolios", "user_portfolio_permissions"]
  end
end

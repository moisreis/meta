# === user_portfolio_permission
#
# @author Moisés Reis
# @added 11/21/2025
# @package *Meta*
# @description Defines the relationship between a **User**
#              and a **Portfolio** to manage access and permission levels.
# @category *Model*
#
# Usage:: - *[what]* This model represents an explicit permission that one **User** has on another user's **Portfolio**.
#         - *[how]* It uses foreign keys to link to the **User** and **Portfolio** models and includes
#                   validations to ensure a user is not granted permission to their
#                   own portfolio and that permission levels are always valid.
#         - *[why]* It is necessary to implement a secure sharing mechanism,
#                   allowing portfolio owners to delegate read-only or full management access to other users.
#
# Attributes:: - *[:user_id]* @integer - the ID of the user who is granted the permission.
#              - *[:portfolio_id]* @integer - the ID of the portfolio to which the permission applies.
#              - *[:permission_level]* @string - the access level granted, which is either 'read' or 'crud'.
#
class UserPortfolioPermission < ApplicationRecord

  PERMISSION_LEVELS = %w[read crud].freeze

  belongs_to :user
  belongs_to :portfolio

  validates :user_id, presence: true
  validates :portfolio_id, presence: true
  validates :permission_level, presence: true, inclusion: {
    in: PERMISSION_LEVELS,
    message: "%{value} isn't a valid permission level"
  }
  validates :user_id, uniqueness: {
    scope: :portfolio_id,
    message: "already has permission for this portfolio"
  }
  validate :cannot_grant_permission_to_owner

  scope :read_only, -> { where(permission_level: 'read') }
  scope :crud_access, -> { where(permission_level: 'crud') }
  scope :for_user, ->(user) { where(user: user) }
  scope :for_portfolio, ->(portfolio) { where(portfolio: portfolio) }

  # [Method] This method checks if the permission level grants full Create, Read, Update, and Delete (**CRUD**) access.
  def crud_access?
    permission_level == 'crud'
  end

  # [Method] This method checks if the permission level grants only **Read** access.
  def read_only?
    permission_level == 'read'
  end

  # [Method] This method returns a human-readable description for the current `permission_level` attribute.
  def permission_description
    case permission_level
    when 'read'
      'Leitura'
    when 'crud'
      'Edição'
    else
      'Unknown access'
    end
  end

  private

  # [Validation] This private custom validation method prevents a portfolio owner from creating a permission record for themselves.
  #              The portfolio owner already has implicit full access, so this prevents redundant and potentially confusing database entries.
  def cannot_grant_permission_to_owner
    return unless user && portfolio

    if user == portfolio.user
      errors.add(:user, "cannot grant permission to self")
    end
  end
end
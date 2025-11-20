# === portfolio
#
# @author Moisés Reis
# @added 11/15/2025
# @package *Meta*
# @description Defines the **Portfolio** model, which represents an investment portfolio.
#              It organizes ownership, permissions, fund allocations, and historical
#              performance. It interacts with **User**, **FundInvestment**, and
#              **UserPortfolioPermission** to manage access and financial data.
# @category *Model*
#
# Usage:: - *[what]* represents an investment portfolio that belongs to a user and groups investments
#         - *[how]* manages associations, enforces validations, provides scopes for permission-based access, and calculates aggregated financial values
#         - *[why]* centralizes investment data, access control, and allocation logic to maintain consistency across the app
#
# Attributes:: - *[:name]* @string - the portfolio’s display name
#              - *[:user_id]* @integer - the id of the owning **User**
#
class Portfolio < ApplicationRecord

  # [Associations] Connects a portfolio to its owner, authorized users, fund allocations, and performance logs.
  belongs_to :user
  has_many :fund_investments, dependent: :destroy
  has_many :investment_funds, through: :fund_investments
  has_many :user_portfolio_permissions, dependent: :destroy
  has_many :authorized_users, through: :user_portfolio_permissions, source: :user
  has_many :performance_histories, dependent: :destroy

  # [Validations] Ensures essential data is present and correctly formatted.
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :user_id, presence: true

  # [Scopes] Retrieves portfolios available to a given user based on permissions or ownership.
  scope :for_user, ->(user) {
    left_joins(:user_portfolio_permissions)
      .where("portfolios.user_id = ? OR user_portfolio_permissions.user_id = ?", user.id, user.id)
      .distinct
  }

  # [Scopes] Selects portfolios that the user is allowed to read.
  scope :readable_by, ->(user) {
    where(user_id: user.id)
      .or(
        joins(:user_portfolio_permissions)
          .where(user_portfolio_permissions: { user_id: user.id })
      )
  }

  # [Scopes] Selects portfolios that the user is allowed to fully manage.
  scope :manageable_by, ->(user) {
    where(user_id: user.id)
      .or(
        joins(:user_portfolio_permissions)
          .where(user_portfolio_permissions: { user_id: user.id, permission_level: 'crud' })
      )
  }

  # [Method] Returns the total invested capital across all fund allocations.
  def total_invested_value
    fund_investments.sum(:total_invested_value) || BigDecimal('0')
  end

  # [Method] Returns the total number of quotas held across all investments.
  def total_quotas_held
    fund_investments.sum(:total_quotas_held) || BigDecimal('0')
  end

  # [Method] Checks whether the total allocation percentage is within valid limits.
  def valid_allocations?
    total_percentage = fund_investments.sum(:percentage_allocation) || BigDecimal('0')
    total_percentage <= BigDecimal('100')
  end

  # [Method] Lists the attributes that Ransack allows for searching and filtering.
  #          Ensures the query interface includes only safe and relevant fields.
  def self.ransackable_attributes(auth_object = nil)
    %w[id name created_at updated_at user_id]
  end

  # [Method] Lists the associations that Ransack allows for querying.
  #          Restricts the searchable relations to maintain clarity and security.
  def self.ransackable_associations(auth_object = nil)
    %w[user]
  end

end

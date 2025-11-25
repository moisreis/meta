# === portfolio
#
# @author Moisés Reis
# @added 11/25/2025
# @package *Meta*
# @description This class represents a collection of a user's investments, grouping together
#              various **FundInvestment** records. It acts as the central hub for calculating
#              total portfolio value and managing access permissions for other **User** records.
# @category *Model*
#
# Usage:: - *[What]* This code block defines a user-owned container for managing and tracking a set of specific **FundInvestment** holdings.
#         - *[How]* It aggregates financial metrics from its associated investments and uses the **user_portfolio_permissions** table to define sharing rules.
#         - *[Why]* The application needs this class to give the **User** a way to organize their holdings, monitor total performance, and delegate viewing access.
#
# Attributes:: - *user_id* @integer - The unique ID of the **User** who owns this portfolio.
#              - *name* @string - A user-friendly name assigned to this portfolio (e.g., "Retirement Savings").
#
class Portfolio < ApplicationRecord

  # Explanation:: This establishes a direct link, indicating that every **Portfolio**
  #               is owned by a single **User**.
  belongs_to :user

  # Explanation:: This establishes a one-to-many relationship, linking this portfolio
  #               to all individual **FundInvestment** records it contains, and destroys them on deletion.
  has_many :fund_investments, dependent: :destroy

  # Explanation:: This establishes a through-relationship, providing easy access to
  #               all unique **InvestmentFunds** contained within the portfolio's holdings.
  has_many :investment_funds, through: :fund_investments

  # Explanation:: This establishes a one-to-many relationship, tracking explicit access
  #               rules given to other users via **UserPortfolioPermissions**.
  has_many :user_portfolio_permissions, dependent: :destroy

  # Explanation:: This establishes a through-relationship, providing easy access to
  #               the **User** records that have been granted access permissions to this portfolio.
  has_many :authorized_users, through: :user_portfolio_permissions, source: :user

  # Explanation:: This establishes a one-to-many relationship for storing historical
  #               performance metrics related to this entire portfolio over time.
  has_many :performance_histories, dependent: :destroy

  # Explanation:: This validates that the portfolio's name is present and must be
  #               between 2 and 100 characters long.
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }

  # Explanation:: This validates that the **Portfolio** must always be associated
  #               with a valid owning **User**.
  validates :user_id, presence: true

  # Explanation:: This defines a query scope that retrieves all portfolios that the given
  #               **User** either owns directly or has been granted explicit permissions to view.
  scope :for_user, ->(user) {
    left_joins(:user_portfolio_permissions)
      .where("portfolios.user_id = ? OR user_portfolio_permissions.user_id = ?", user.id, user.id)
      .distinct
  }

  # Explanation:: This defines a query scope that retrieves all portfolios that the given
  #               **User** can read, combining owned portfolios with those shared via permissions.
  scope :readable_by, ->(user) {
    where(user_id: user.id)
      .or(
        joins(:user_portfolio_permissions)
          .where(user_portfolio_permissions: { user_id: user.id })
      )
  }

  # Explanation:: This defines a query scope that retrieves all portfolios that the given
  #               **User** can fully manage, including those they own and those shared with 'crud' (create/read/update/delete) permission.
  scope :manageable_by, ->(user) {
    where(user_id: user.id)
      .or(
        joins(:user_portfolio_permissions)
          .where(user_portfolio_permissions: { user_id: user.id, permission_level: 'crud' })
      )
  }

  # == total_invested_value
  #
  # @author Moisés Reis
  # @category *Calculation*
  #
  # Calculation:: This method calculates the sum of the original investment amounts across all **FundInvestment** records within the portfolio.
  #              It provides the total capital invested by the user into this portfolio.
  #
  def total_invested_value
    fund_investments.sum(:total_invested_value) || BigDecimal('0')
  end

  # == total_quotas_held
  #
  # @author Moisés Reis
  # @category *Calculation*
  #
  # Calculation:: This method calculates the total number of quotas held across all **FundInvestment** records within the portfolio.
  #              It provides the combined count of all units held across various funds.
  #
  def total_quotas_held
    fund_investments.sum(:total_quotas_held) || BigDecimal('0')
  end

  # == valid_allocations?
  #
  # @author Moisés Reis
  # @category *Validation*
  #
  # Validation:: This method checks if the sum of all `percentage_allocation` fields in the associated **FundInvestment** records is 100% or less.
  #              It ensures the portfolio's allocation percentages are mathematically sound.
  #
  def valid_allocations?

    # Explanation:: This sums the `percentage_allocation` attribute from all fund investments.
    total_percentage = fund_investments.sum(:percentage_allocation) || BigDecimal('0')

    # Explanation:: This returns true if the total calculated percentage is less than or equal to 100.
    total_percentage <= BigDecimal('100')
  end

  # == ransackable_attributes
  #
  # @author Moisés Reis
  # @category *Query*
  #
  # Query:: This method defines which columns of the **Portfolio** model can be safely searched or filtered by users through advanced query tools like Ransack.
  #         It restricts the searchable fields to basic identifiers and audit dates.
  #
  def self.ransackable_attributes(auth_object = nil)
    %w[id name created_at updated_at user_id]
  end

  # == ransackable_associations
  #
  # @author Moisés Reis
  # @category *Query*
  #
  # Query:: This method defines which associated models (relationships) of the **Portfolio** model can be included in search and filtering operations by Ransack.
  #         It restricts querying only through the owner **User** association.
  #
  def self.ransackable_associations(auth_object = nil)
    %w[user]
  end
end
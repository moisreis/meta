# === fund_investment
#
# @author Moisés Reis
# @added 11/25/2025
# @package *Meta*
# @description This class tracks a user's holding in a single **InvestmentFund** within a **Portfolio**.
#              It aggregates all applications (purchases) and redemptions (sales) to maintain the current
#              total investment value and quota balance for that specific fund.
# @category *Model*
#
# Usage:: - *[What]* This code block represents the core record of an investment in a particular fund,
#           acting as a link between a user's **Portfolio** and the actual **InvestmentFund** product.
#         - *[How]* It uses data from the **applications** and **redemptions** associations to calculate
#           metrics like current market value and return percentage, and enforces rules like allocation limits.
#         - *[Why]* The application needs this single record to serve as the source of truth for all
#           holding data, performance calculations, and reporting related to one specific investment product.
#
# Attributes:: - *portfolio_id* @integer - The unique ID of the user's portfolio that holds this investment.
#              - *investment_fund_id* @integer - The unique ID of the fund being invested in.
#              - *total_invested_value* @decimal - The total monetary amount originally invested into this fund.
#              - *total_quotas_held* @decimal - The current number of quotas the portfolio holds in this fund.
#              - *percentage_allocation* @decimal - The percentage weight of this fund within the overall portfolio.
#
class FundInvestment < ApplicationRecord

  # Explanation:: This establishes a direct link, indicating that every **FundInvestment**
  #               record belongs to a single parent **Portfolio** that contains it.
  belongs_to :portfolio

  # Explanation:: This establishes a direct link, indicating that every **FundInvestment**
  #               record is associated with a single **InvestmentFund** product.
  belongs_to :investment_fund

  # Explanation:: This establishes a one-to-many relationship, tracking all investment purchases
  #               made into this fund, and destroys them if the parent is destroyed.
  has_many :applications, dependent: :destroy

  # Explanation:: This establishes a one-to-many relationship, tracking all fund withdrawals
  #               made from this fund, and destroys them if the parent is destroyed.
  has_many :redemptions, dependent: :destroy

  # Explanation:: This establishes a one-to-many relationship for storing historical
  #               performance metrics related to this investment over time.
  has_many :performance_histories, dependent: :destroy

  # Explanation:: This validates that the record must always be associated with a valid
  #               **Portfolio** before it can be saved to the database.
  validates :portfolio_id, presence: true

  # Explanation:: This validates that the record must always be associated with a valid
  #               **InvestmentFund** before it can be saved to the database.
  validates :investment_fund_id, presence: true

  # Explanation:: This validates that the total invested monetary value is present
  #               and must be zero or a positive number.
  validates :total_invested_value, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # Explanation:: This validates that the total number of quotas held is present
  #               and must be zero or a positive number.
  validates :total_quotas_held, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # Explanation:: This validates that the allocation percentage is present and must be
  #               a value between 0% and 100%, inclusive.
  validates :percentage_allocation, presence: true, numericality: {
    greater_than_or_equal_to: 0,
    less_than_or_equal_to: 100
  }

  # Explanation:: This ensures that a single **Portfolio** cannot have more than one
  #               **FundInvestment** record for the same **InvestmentFund**.
  validates :investment_fund_id, uniqueness: { scope: :portfolio_id }

  # Explanation:: This calls a custom private validation method to ensure that this
  #               investment's allocation percentage does not cause the total portfolio allocation to exceed 100%.
  validate :portfolio_allocation_within_limits

  # Explanation:: This defines a query scope that easily retrieves all **FundInvestment**
  #               records where the quota balance is greater than zero, meaning the investment is still active.
  scope :active, -> { where('total_quotas_held > 0') }

  # Explanation:: This defines a query scope that orders the investment records
  #               from the highest to the lowest percentage allocation within the portfolio.
  scope :by_allocation, -> { order(percentage_allocation: :desc) }

  # Explanation:: This defines a complex query scope that retrieves all **FundInvestment**
  #               records accessible to a specific **User**, either through ownership or explicit permissions.
  scope :accessible_to, ->(user) {

    # Explanation:: This returns all investments if the **User** has administrative privileges.
    if user.admin?
      all
    else

      # Explanation:: This performs a database join to find investments that are either owned
      #               by the **User** or have explicit permissions granted via **user_portfolio_permissions**.
      joins(:portfolio)
        .joins("LEFT JOIN user_portfolio_permissions ON user_portfolio_permissions.portfolio_id = portfolios.id")
        .where(
          "portfolios.user_id = ? OR user_portfolio_permissions.user_id = ?",
          user.id, user.id
        )
        .distinct
    end
  }

  # Explanation:: This defines a query scope that finds all **FundInvestment** records
  #               whose parent **Portfolio** is readable by the given **User**.
  scope :readable_by, ->(user) {
    joins(fund_investments: :portfolio)
      .where(portfolios: { id: Portfolio.readable_by(user).select(:id) })
      .distinct
  }

  # Explanation:: This defines a query scope that finds all **FundInvestment** records
  #               that are contained within a **Portfolio** owned by the given **User**.
  scope :owned_by, ->(user) {
    joins(:portfolio).where(portfolios: { user_id: user.id })
  }

  # Explanation:: This defines a query scope that finds all **FundInvestment** records
  #               for which the **User** has non-owner permissions, meaning they can view but do not own the parent **Portfolio**.
  scope :with_permissions_for, ->(user) {
    joins(portfolio: :user_portfolio_permissions)
      .where(user_portfolio_permissions: { user_id: user.id })
      .where.not(portfolios: { user_id: user.id })
  }

  # == current_market_value
  #
  # @author Moisés Reis
  # @category *Calculation*
  #
  # Calculation:: This method calculates the current monetary worth of the investment by multiplying the total number of quotas held by the fund's latest quota price.
  #               It provides the up-to-date value of the holding.
  #
  def current_market_value
    latest_quota_value = investment_fund.quota_value_on(Date.new(2026, 1, 30))
    return BigDecimal('0') unless latest_quota_value && total_quotas_held

    value = total_quotas_held * latest_quota_value
    # Zera resíduos menores que R$1,00
    value < BigDecimal('1') ? BigDecimal('0') : value
  end

  def period_return_percentage
    latest_perf = performance_histories.order(period: :desc).first
    return latest_perf.monthly_return if latest_perf

    base = initial_invested_value
    return BigDecimal('0') if base.zero?

    (total_gain / base) * 100
  end


  def current_market_value_on(date)
    quota_value = investment_fund.quota_value_on(date)
    return BigDecimal('0') unless quota_value

    quotas = applications.where("cotization_date <= ?", date).sum(:number_of_quotas) -
             redemptions.where("cotization_date <= ?", date).sum(:redeemed_quotas)

    quotas * quota_value
  end

  # == unrealized_gain_loss
  #
  # @author Moisés Reis
  # @category *Calculation*
  #
  # Calculation:: This method calculates the profit or loss that has not yet been realized by selling the investment.
  #               It subtracts the original total invested value from the current market value.
  #
  def unrealized_gain_loss
    current_market_value - total_invested_value
  end

  # == return_percentage
  #
  # @author Moisés Reis
  # @category *Calculation*
  #
  # Calculation:: This method determines the return on investment (ROI) as a percentage.
  #               It divides the unrealized gain or loss by the original total invested value and multiplies by 100.
  #
  def return_percentage

    # Explanation:: This returns zero if the total invested value is zero, preventing a division-by-zero error.
    return BigDecimal('0') if total_invested_value.zero?

    # Explanation:: This calculates the return by dividing the gain/loss by the initial investment
    #               and scaling the result to a percentage.
    (unrealized_gain_loss / total_invested_value) * 100
  end

  # == total_applications
  #
  # @author Moisés Reis
  # @category *Calculation*
  #
  # Calculation:: This method sums up the financial values of all **Application** records associated with this investment.
  #               It provides the total gross amount of money invested over time.
  #
  def total_applications
    applications.sum(:financial_value) || BigDecimal('0')
  end

  def total_redemptions
    redemptions.sum(:redeemed_liquid_value)
  end

  def total_gain
    total_redemptions + current_market_value - total_applications
  end

  def initial_date
    applications.minimum(:cotization_date)
  end

  def initial_invested_value
    return BigDecimal('0') unless initial_date
    applications.where(cotization_date: initial_date).sum(:financial_value)
  end

  def period_applications
    return BigDecimal('0') unless initial_date
    applications.where('cotization_date > ?', initial_date).sum(:financial_value)
  end

  def net_movement
    period_applications - total_redemptions
  end

  # == total_redemptions
  #
  # @author Moisés Reis
  # @category *Calculation*
  #
  # Calculation:: This method sums up the liquid (net) financial values of all **Redemption** records associated with this investment.
  #               It provides the total amount of money withdrawn over time.
  #
  def total_redemptions
    redemptions.sum(:redeemed_liquid_value) || BigDecimal('0')
  end

  private

  # == portfolio_allocation_within_limits
  #
  # @author Moisés Reis
  # @category *Validation*
  #
  # Validation:: This custom validation ensures that the `percentage_allocation`
  #              for this fund, when added to all other fund allocations in the same **Portfolio**, does not exceed 100%.
  #
  def portfolio_allocation_within_limits

    # Explanation:: This exits the validation if the parent **Portfolio** or the allocation percentage is missing.
    return unless portfolio && percentage_allocation

    # Explanation:: This calculates the sum of all existing allocation percentages in the **Portfolio**,
    #               plus the new allocation for the current fund investment being saved.
    total_allocation = portfolio.fund_investments
                                .where.not(id: id)
                                .sum(:percentage_allocation) + percentage_allocation

    # Explanation:: This adds a validation error if the calculated total allocation exceeds the 100% limit.
    if total_allocation > 100
      errors.add(:percentage_allocation, "it exceeds the portfolio's total allocation limit of 100%")
    end
  end

  # == ransackable_attributes
  #
  # @author Moisés Reis
  # @category *Query*
  #
  # Query:: This method defines which columns of the **FundInvestment** model can be safely searched or
  #         filtered by users through advanced query tools like Ransack.
  #         It explicitly lists all the safe, searchable attributes.
  #
  def self.ransackable_attributes(auth_object = nil)
    [
      "created_at",
      "id",
      "investment_fund_id",
      "percentage_allocation",
      "portfolio_id",
      "total_invested_value",
      "total_quotas_held",
      "updated_at"
    ]
  end

  # == ransackable_associations
  #
  # @author Moisés Reis
  # @category *Query*
  #
  # Query:: This method defines which associated models (relationships) of the **FundInvestment**
  #         model can be included in search and filtering operations by Ransack.
  #         It ensures only valid relationships are exposed for querying.
  #
  def self.ransackable_associations(auth_object = nil)
    [
      "applications",
      "investment_fund",
      "performance_histories",
      "portfolio",
      "redemptions"
    ]
  end
end
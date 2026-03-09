# === fund_investment.rb
#
# Description:: Tracks the relationship between a specific portfolio and an investment fund.
#               This model manages the balances of quotas held and the financial value
#               invested by a user within a particular fund.
#
# Usage:: - *What* - Represents a specific holding of a fund within a user's collection.
#         - *How* - It calculates market values, returns, and validates allocation limits.
#         - *Why* - To provide a consolidated view of fund performance and ownership.
#
# Attributes:: - *@portfolio_id* [Integer] - The ID of the associated +Portfolio+.
#              - *@investment_fund_id* [Integer] - The ID of the associated +InvestmentFund+.
#              - *@total_invested_value* [Decimal] - The total amount of money put into the fund.
#              - *@total_quotas_held* [Decimal] - The number of shares or quotas currently owned.
#              - *@percentage_allocation* [Decimal] - The target weight of this fund in the portfolio.
#
class FundInvestment < ApplicationRecord

  belongs_to :portfolio
  belongs_to :investment_fund

  has_many :applications,         dependent: :destroy
  has_many :redemptions,          dependent: :destroy
  has_many :performance_histories, dependent: :destroy

  # =============================================================
  #                        Configuration
  # =============================================================

  validates :portfolio_id,       presence: true
  validates :investment_fund_id, presence: true

  validates :total_invested_value, presence: true,
            numericality: { greater_than_or_equal_to: 0 }

  validates :total_quotas_held, presence: true,
            numericality: { greater_than_or_equal_to: 0 }

  validates :percentage_allocation, presence: true, numericality: {
    greater_than_or_equal_to: 0,
    less_than_or_equal_to:    100
  }

  validates :investment_fund_id, uniqueness: { scope: :portfolio_id }

  validate :portfolio_allocation_within_limits

  # Allows the system to temporarily bypass allocation limit validation during
  # automated balance updates or bulk migrations.
  attr_accessor :skip_allocation_validation

  # =============================================================
  #                           Scopes
  # =============================================================

  scope :active, -> { where("total_quotas_held > 0") }

  scope :by_allocation, -> { order(percentage_allocation: :desc) }

  scope :accessible_to, ->(user) {
    if user.admin?
      all
    else
      joins(:portfolio)
        .joins("LEFT JOIN user_portfolio_permissions ON user_portfolio_permissions.portfolio_id = portfolios.id")
        .where(
          "portfolios.user_id = ? OR user_portfolio_permissions.user_id = ?",
          user.id, user.id
        )
        .distinct
    end
  }

  scope :readable_by, ->(user) {
    joins(:portfolio)
      .where(portfolios: { id: Portfolio.readable_by(user).select(:id) })
      .distinct
  }

  scope :owned_by, ->(user) {
    joins(:portfolio).where(portfolios: { user_id: user.id })
  }

  scope :with_permissions_for, ->(user) {
    joins(portfolio: :user_portfolio_permissions)
      .where(user_portfolio_permissions: { user_id: user.id })
      .where.not(portfolios: { user_id: user.id })
  }

  # =============================================================
  #                        Public Methods
  # =============================================================

  # == update_balances!
  #
  # @author Moisés Reis
  #
  # Updates total_quotas_held and total_invested_value atomically using a
  # row-level lock to prevent race conditions when concurrent requests
  # (e.g. two simultaneous redemptions) attempt to adjust the same record.
  #
  # Parameters:: - *quotas_delta* - The change in the number of quotas.
  #              - *value_delta* - The change in the total invested amount.
  #
  # Returns:: - True if the record was successfully saved.
  def update_balances!(quotas_delta:, value_delta:)
    with_lock do
      self.skip_allocation_validation = true
      self.total_quotas_held   = (total_quotas_held   || 0) + quotas_delta
      self.total_invested_value = (total_invested_value || 0) + value_delta
      save!
    end
  end

  # == current_market_value
  #
  # @author Moisés Reis
  #
  # Calculates the market value of quotas currently held at the given date.
  # Always pass an explicit date when computing historical or report figures —
  # the default Date.current is correct only for live-ticker display.
  #
  # Parameters:: - *date* - The reference date for the quota price lookup.
  #
  # Returns:: - Market value as a BigDecimal, or zero when no quota is available.
  def current_market_value(date = Date.current)
    quota = investment_fund.quota_value_on(date)
    return BigDecimal("0") unless quota && total_quotas_held

    value = total_quotas_held * quota
    value < BigDecimal("1") ? BigDecimal("0") : value
  end

  # == current_market_value_on
  #
  # @author Moisés Reis
  #
  # Reconstructs the market value at a historical point in time by replaying
  # every application and redemption up to that date, then pricing the
  # resulting quota balance at the closest available quota valuation.
  #
  # Parameters:: - *date* - The historical date to calculate the value for.
  #
  # Returns:: - The historical financial value as a BigDecimal.
  def current_market_value_on(date)
    quota = investment_fund.quota_value_on(date)
    return BigDecimal("0") unless quota

    quotas = applications.where("cotization_date <= ?", date).sum(:number_of_quotas) -
             redemptions.where("cotization_date <= ?", date).sum(:redeemed_quotas)

    BigDecimal(quotas.to_s) * quota
  end

  # == unrealized_gain_loss
  #
  # @author Moisés Reis
  #
  # Difference between current market value and the denormalised total_invested_value.
  # Pass a date when a historical reference is needed.
  #
  # Returns:: - Gain (positive) or loss (negative) as a BigDecimal.
  def unrealized_gain_loss(date = Date.current)
    current_market_value(date) - total_invested_value
  end

  # == return_percentage
  #
  # @author Moisés Reis
  #
  # Simple cost-basis return: unrealised gain relative to total_invested_value.
  # Suitable for a quick snapshot but does not account for cash-flow timing.
  # Use period_return_percentage for a time-weighted rate.
  #
  # Returns:: - The percentage of return as a BigDecimal.
  def return_percentage(date = Date.current)
    return BigDecimal("0") if total_invested_value.zero?

    (unrealized_gain_loss(date) / total_invested_value) * 100
  end

  # == total_applications
  #
  # @author Moisés Reis
  #
  # Sums all money ever contributed to this fund position (gross inflows).
  #
  # Returns:: - The sum of all application financial values as a BigDecimal.
  def total_applications
    BigDecimal(applications.sum(:financial_value).to_s)
  end

  # == total_redemptions
  #
  # @author Moisés Reis
  #
  # Sums all cash ever withdrawn from this fund position (gross outflows).
  #
  # Returns:: - The sum of all redeemed liquid values as a BigDecimal.
  def total_redemptions
    BigDecimal(redemptions.sum(:redeemed_liquid_value).to_s)
  end

  # == total_gain
  #
  # @author Moisés Reis
  #
  # Absolute profit or loss since inception, marked to a reference date:
  #
  #   total_gain = (current_market_value + total_redemptions) − total_applications
  #
  # Interpretation: the sum of what you can still sell (current_market_value)
  # plus what you already received (total_redemptions), minus everything you
  # ever put in (total_applications). Negative means a loss.
  #
  # Parameters:: - *date* - Reference date for the quota price. Pass an explicit
  #                date for historical/report views; omit for today's value.
  #
  # Returns:: - Gain or loss as a BigDecimal.
  def total_gain(date = Date.current)
    total_redemptions + current_market_value(date) - total_applications
  end

  # == initial_date
  #
  # @author Moisés Reis
  #
  # The cotization date of the very first application — used as the period
  # start for since-inception Modified Dietz calculations.
  #
  # Returns:: - A Date or nil when no applications exist.
  def initial_date
    applications.minimum(:cotization_date)
  end

  # == initial_invested_value
  #
  # @author Moisés Reis
  #
  # Sum of financial values for applications made on the first day only.
  #
  # Returns:: - The opening capital contribution as a BigDecimal.
  def initial_invested_value
    return BigDecimal("0") unless initial_date
    BigDecimal(applications.where(cotization_date: initial_date).sum(:financial_value).to_s)
  end

  # == period_applications
  #
  # @author Moisés Reis
  #
  # Sum of all applications made after the very first cotization date.
  #
  # Returns:: - Subsequent gross inflows as a BigDecimal.
  def period_applications
    return BigDecimal("0") unless initial_date
    BigDecimal(applications.where("cotization_date > ?", initial_date).sum(:financial_value).to_s)
  end

  # == net_movement
  #
  # @author Moisés Reis
  #
  # Net cash flow after the opening day: subsequent applications minus all redemptions.
  #
  # Returns:: - Net flow as a BigDecimal.
  def net_movement
    period_applications - total_redemptions
  end

  # == dietz_weighted_cash_flow
  #
  # @author Moisés Reis
  #
  # Computes the Modified Dietz denominator for the since-inception period:
  #
  #   W = Σ [ CF_i × (end_date − flow_date_i) / total_days ]
  #
  # Each application is a positive flow; each redemption is a negative flow.
  # Flows on the start date carry full weight (ratio = 1.0).
  # Flows on the end date carry zero weight (ratio = 0.0).
  #
  # Parameters:: - *end_date* - The period end date (inclusive).
  #
  # Returns:: - Weighted cash flow as a BigDecimal, or nil when there are no
  #             applications (position not yet opened).
  def dietz_weighted_cash_flow(end_date = Date.current)
    start_date = initial_date
    return nil unless start_date

    # Standard Modified Dietz: period length = end_date − start_date (no +1).
    # This ensures the first application (on start_date) carries weight 1.0,
    # meaning it was invested for the full period. Adding 1 here inflates the
    # denominator and deflates all weights, producing an incorrect return.
    total_days = BigDecimal((end_date - start_date).to_i.to_s)
    return nil if total_days <= 0

    weighted = BigDecimal("0")

    applications.each do |app|
      next unless app.cotization_date && app.financial_value
      days_remaining = (end_date - app.cotization_date).to_i
      next if days_remaining < 0  # ignore flows after end_date
      weight    = BigDecimal(days_remaining.to_s) / total_days
      weighted += BigDecimal(app.financial_value.to_s) * weight
    end

    redemptions.each do |red|
      next unless red.cotization_date && red.redeemed_liquid_value
      days_remaining = (end_date - red.cotization_date).to_i
      next if days_remaining < 0
      weight    = BigDecimal(days_remaining.to_s) / total_days
      weighted -= BigDecimal(red.redeemed_liquid_value.to_s) * weight
    end

    weighted
  end

  # == latest_monthly_return
  #
  # @author Moisés Reis
  #
  # Returns the most recent single-month return stored in performance_histories,
  # as calculated by PerformanceCalculationJob for the last closed month.
  # Use this when you need the *last month's* isolated return.
  #
  # Returns:: - Monthly return percentage as a BigDecimal, or nil.
  def latest_monthly_return
    performance_histories.order(period: :desc).first&.monthly_return
  end

  # == period_return_percentage
  #
  # @author Moisés Reis
  #
  # Since-inception cumulative return using the Modified Dietz method:
  #
  #   R = total_gain(date) / dietz_weighted_cash_flow(date)
  #
  # This is always computed from raw transactions regardless of whether
  # performance_histories exist. A stored monthly_return covers only one
  # isolated month and must never be used as a proxy for the cumulative
  # since-inception rate — doing so was the source of the 1.01% vs 1.18%
  # discrepancy (December's monthly return was returned instead of the
  # full since-inception Dietz calculation across both applications).
  #
  # Parameters:: - *date* - Reference date for quota pricing and period end.
  #                Defaults to today for a live view; pass an explicit date
  #                for historical/report contexts.
  #
  # Returns:: - Cumulative return as a percentage BigDecimal, or zero when
  #             the weighted denominator is zero or undeterminable.
  def period_return_percentage(date = Date.current)
    gain     = total_gain(date)
    weighted = dietz_weighted_cash_flow(date)

    return BigDecimal("0") if weighted.nil? || weighted.zero?

    (gain / weighted) * 100
  end

  # == self.ransackable_attributes
  #
  # @author Moisés Reis
  #
  # Defines which data fields can be used for searching.
  #
  # Returns:: - An array of searchable attribute names.
  def self.ransackable_attributes(auth_object = nil)
    %w[
      created_at
      id
      investment_fund_id
      percentage_allocation
      portfolio_id
      total_invested_value
      total_quotas_held
      updated_at
    ]
  end

  # == self.ransackable_associations
  #
  # @author Moisés Reis
  #
  # Defines which related models can be included in searches.
  #
  # Returns:: - An array of searchable association names.
  def self.ransackable_associations(auth_object = nil)
    %w[
      applications
      investment_fund
      performance_histories
      portfolio
      redemptions
    ]
  end

  # =============================================================
  #                        Private Methods
  # =============================================================

  private

  # == portfolio_allocation_within_limits
  #
  # @author Moisés Reis
  #
  # Prevents the total portfolio from exceeding 100% capacity.
  #
  # Returns:: - Adds an error to the record if the limit is exceeded.
  def portfolio_allocation_within_limits
    return if skip_allocation_validation
    return unless portfolio && percentage_allocation

    total_allocation = portfolio.fund_investments
                                .where.not(id: id)
                                .sum(:percentage_allocation) + percentage_allocation

    if total_allocation > 100
      errors.add(:percentage_allocation, "it exceeds the portfolio's total allocation limit of 100%")
    end
  end
end
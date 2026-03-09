# === portfolio.rb
#
# Description:: Represents a user's collection of investment funds and financial assets.
#               This model organizes holdings, tracks performance history, and manages
#               permissions for users to view or edit their investment portfolios.
#
# Usage:: - *What* - Acts as the primary organizational unit for a user's financial assets.
#         - *How* - It aggregates data from multiple investments to calculate total value,
#           gains, and performance metrics across different time periods.
#         - *Why* - Necessary to provide a centralized interface for tracking wealth
#           growth and managing multiple investment strategies within the system.
#
# Attributes:: - *@name* [String] - The name given by the user to identify this portfolio.
#              - *@annual_interest_rate* [Decimal] - The expected return rate target set for the portfolio.
#              - *@user_id* [Integer] - The ID of the owner who created this portfolio.
#
class Portfolio < ApplicationRecord

  belongs_to :user

  has_many :checking_accounts,         dependent: :destroy
  has_many :fund_investments,          dependent: :destroy
  has_many :investment_funds,          through: :fund_investments
  has_many :user_portfolio_permissions, dependent: :destroy
  has_many :authorized_users,          through: :user_portfolio_permissions, source: :user
  has_many :performance_histories,     dependent: :destroy

  validates :name,                 presence: true, length: { minimum: 2, maximum: 100 }
  validates :annual_interest_rate, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :user_id,              presence: true

  # =============================================================
  # Scopes
  # =============================================================

  scope :for_user, ->(user) {
    left_joins(:user_portfolio_permissions)
      .where("portfolios.user_id = ? OR user_portfolio_permissions.user_id = ?", user.id, user.id)
      .distinct
  }

  scope :readable_by, ->(user) {
    where(user_id: user.id)
      .or(joins(:user_portfolio_permissions).where(user_portfolio_permissions: { user_id: user.id }))
  }

  scope :manageable_by, ->(user) {
    where(user_id: user.id)
      .or(
        joins(:user_portfolio_permissions).where(
          user_portfolio_permissions: { user_id: user.id, permission_level: "crud" }
        )
      )
  }

  # =============================================================
  # Public Methods
  # =============================================================

  # == total_invested_value
  #
  # @author Moisés Reis
  #
  # Calculates the sum of all invested capital across all funds in this portfolio.
  #
  # Returns:: - The total invested value as a BigDecimal.
  def total_invested_value
    fund_investments.sum(:total_invested_value) || BigDecimal("0")
  end

  # == total_quotas_held
  #
  # @author Moisés Reis
  #
  # Aggregates the total number of quotas held across all individual investments.
  #
  # Returns:: - The total quantity of quotas as a BigDecimal.
  def total_quotas_held
    fund_investments.sum(:total_quotas_held) || BigDecimal("0")
  end

  # == total_current_market_value
  #
  # @author Moisés Reis
  #
  # Calculates the total current worth of the portfolio using a single SQL query
  # that joins fund_valuations to avoid N+1 queries per fund.
  #
  # Returns:: - The current market value as a BigDecimal.
  def total_current_market_value
    result = fund_investments
               .joins(investment_fund: :fund_valuations)
               .where(
                 "public.fund_valuations.date = (
                   SELECT MAX(fv2.date)
                   FROM public.fund_valuations fv2
                   WHERE fv2.fund_cnpj = public.investment_funds.cnpj
                     AND EXTRACT(DOW FROM fv2.date) NOT IN (0, 6)
                     AND fv2.date <= ?
                 )", Date.current
               )
               .sum("public.fund_investments.total_quotas_held * public.fund_valuations.quota_value")

    BigDecimal(result.to_s)
  rescue StandardError => e
    Rails.logger.warn("[Portfolio#total_current_market_value] SQL optimisation failed, falling back: #{e.message}")
    fund_investments.includes(:investment_fund).sum(&:current_market_value)
  end

  # == total_gain
  #
  # @author Moisés Reis
  #
  # Computes the total financial profit or loss realised by the portfolio.
  #
  # Returns:: - The total gain as a BigDecimal.
  def total_gain
    fund_investments.includes(:investment_fund, :applications, :redemptions).sum(&:total_gain)
  end

  # == meta
  #
  # @author Moisés Reis
  #
  # Determines the portfolio benchmark target by adding the portfolio's interest rate
  # to the current IPCA economic index value.
  #
  # Parameters:: - *reference_date* - The date used to fetch the current IPCA index.
  #
  # Returns:: - The target meta rate as a Decimal.
  def meta(reference_date = Date.current)
    ipca_index = EconomicIndex.find_by(abbreviation: "IPCA")
    ipca_value = ipca_index&.value_on(reference_date.beginning_of_month) || BigDecimal("0")
    annual_interest_rate.to_d + ipca_value
  end

  # == valid_allocations?
  #
  # @author Moisés Reis
  #
  # Verifies if the sum of all fund percentage allocations does not exceed 100%.
  #
  # Returns:: - True if allocations are valid, false otherwise.
  def valid_allocations?
    fund_investments.sum(:percentage_allocation) <= BigDecimal("100")
  end

  # == portfolio_return_percentage
  #
  # @author Moisés Reis
  #
  # Calculates the weighted average return for the portfolio based on the latest performance snapshot.
  #
  # Parameters:: - *reference_date* - The period date for which to calculate the return.
  #
  # Returns:: - The calculated weighted return percentage.
  def portfolio_return_percentage(reference_date = nil)
    perfs = performance_histories
              .where(period: reference_date || performance_histories.maximum(:period))
              .includes(:fund_investment)

    return BigDecimal("0") if perfs.empty?

    total_alloc = perfs.sum { |p| p.fund_investment.percentage_allocation.to_d }
    return BigDecimal("0") if total_alloc.zero?

    weighted = perfs.sum { |p| p.monthly_return.to_d * p.fund_investment.percentage_allocation.to_d }
    weighted / total_alloc
  end

  # == portfolio_yearly_return_percentage
  #
  # @author Moisés Reis
  #
  # Calculates the cumulative year-to-date performance, weighted by individual fund allocations.
  #
  # Parameters:: - *reference_date* - The period date used to define the year-to-date range.
  #
  # Returns:: - The weighted year-to-date return percentage.
  def portfolio_yearly_return_percentage(reference_date = nil)
    period = reference_date || performance_histories.maximum(:period)
    return BigDecimal("0") unless period

    perfs = performance_histories
              .where(period: period.beginning_of_year..period)
              .includes(:fund_investment)

    return BigDecimal("0") if perfs.empty?

    weighted    = BigDecimal("0")
    total_alloc = BigDecimal("0")

    perfs.group_by(&:fund_investment_id).each do |_, fund_perfs|
      fi    = fund_perfs.first.fund_investment
      alloc = fi.percentage_allocation.to_d
      accumulated = fund_perfs.sum { |p| p.monthly_return.to_d }
      weighted    += accumulated * alloc
      total_alloc += alloc
    end

    total_alloc > 0 ? weighted / total_alloc : BigDecimal("0")
  end

  # == value_timeline
  #
  # @author Moisés Reis
  #
  # Generates a timeline of the portfolio's cumulative value using SQL aggregation
  # to avoid loading every individual transaction record into memory.
  #
  # Parameters:: - *months_back* - The number of months to include in the timeline.
  #
  # Returns:: - An array of [Date, BigDecimal] pairs representing monthly running totals.
  def value_timeline(months_back = 12)
    app_by_month = Application
                     .joins(:fund_investment)
                     .where(fund_investments: { portfolio_id: id })
                     .where.not(cotization_date: nil)
                     .group("DATE_TRUNC('month', cotization_date)")
                     .sum(:financial_value)

    red_by_month = Redemption
                     .joins(:fund_investment)
                     .where(fund_investments: { portfolio_id: id })
                     .where.not(cotization_date: nil)
                     .group("DATE_TRUNC('month', cotization_date)")
                     .sum(:redeemed_liquid_value)

    all_months = (app_by_month.keys + red_by_month.keys).uniq.sort

    running_total = BigDecimal("0")
    timeline = all_months.map do |month|
      running_total += BigDecimal((app_by_month[month] || 0).to_s)
      running_total -= BigDecimal((red_by_month[month] || 0).to_s)
      [month, running_total]
    end

    timeline.last(months_back)
  end

  # == quota_timeline_by_fund
  #
  # @author Moisés Reis
  #
  # Maps historical quota counts for each investment fund in the portfolio over time.
  #
  # Returns:: - A hash where keys are fund names and values are arrays of date/quota points.
  def quota_timeline_by_fund
    data = {}

    fund_investments.includes(:investment_fund, :applications).each do |fi|
      fund_name      = fi.investment_fund.fund_name
      data[fund_name] = []
      running_quotas  = 0

      fi.applications.order(:cotization_date).each do |app|
        next unless app.cotization_date.present? && app.number_of_quotas.present?
        running_quotas += app.number_of_quotas
        data[fund_name] << [app.cotization_date.strftime("%b/%y"), running_quotas]
      end
    end

    data
  end

  # == self.ransackable_attributes
  #
  # @author Moisés Reis
  #
  # Specifies which portfolio attributes are available for Ransack searches.
  #
  # Returns:: - An array of searchable attribute names.
  def self.ransackable_attributes(auth_object = nil)
    %w[id name created_at updated_at user_id]
  end

  # == self.ransackable_associations
  #
  # @author Moisés Reis
  #
  # Specifies which associations are available for Ransack searches.
  #
  # Returns:: - An array of searchable association names.
  def self.ransackable_associations(auth_object = nil)
    %w[user]
  end
end

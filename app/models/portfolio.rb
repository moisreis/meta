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

  has_many :checking_accounts, dependent: :destroy
  has_many :fund_investments, dependent: :destroy
  has_many :investment_funds, through: :fund_investments
  has_many :user_portfolio_permissions, dependent: :destroy
  has_many :authorized_users, through: :user_portfolio_permissions, source: :user
  has_many :performance_histories, dependent: :destroy

  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :annual_interest_rate, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :user_id, presence: true

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

  # == total_earnings_on
  #
  # @author Moisés Reis
  #
  # Aggregates the total financial earnings recorded for all funds in the portfolio.
  # This method retrieves the sum of earnings from performance history records for a specific period.
  #
  # Parameters::
  # - *date* - The reference date used to identify the specific performance period.
  #
  # Returns::
  # - The total sum of earnings as a BigDecimal.

  def total_earnings_on(date)
    target_period = date.to_date.end_of_month

    performance_histories.where(period: target_period).sum(:earnings)
  end

  # == compounded_yearly_return_on
  #
  # @author Moisés Reis
  #
  # Calculates the compounded year-to-date return by chaining the monthly
  # returns geometrically. Delegates to portfolio_return_percentage for each
  # month to guarantee consistency between the monthly card and the YTD card.
  #
  # Parameters:: - *date* - The reference date defining the year and the final month.
  #
  # Returns:: - The compounded return as a percentage (e.g., 2.42) or 0.0 if no data exists.
  def compounded_yearly_return_on(date)
    periods = performance_histories
                .where(period: date.beginning_of_year..date.end_of_month)
                .pluck(:period)
                .uniq
                .sort

    return 0.0 if periods.empty?

    total_factor = periods.reduce(BigDecimal("1")) do |factor, period|
      monthly = portfolio_return_percentage(period)
      factor * (1 + monthly / 100)
    end

    ((total_factor - 1) * 100).round(2).to_f
  end

  # == total_balance_on
  #
  # @author Moisés Reis
  #
  # Reconstructs the total financial value of the portfolio for a specific date.
  # It iterates through each fund investment, calculates the net quotas held
  # on that date, and multiplies them by the closest available quota value.
  #
  # Parameters::
  # - *date* - The specific date for which to calculate the total balance.
  #
  # Returns::
  # - The total balance as a BigDecimal.

  def total_balance_on(date)
    fund_investments.sum do |fi|
      quotas = reconstruct_quotas_at(fi, date)

      price = closest_quota_value(fi.investment_fund.cnpj, date)

      quotas * (price || 0)
    end
  end

  # == yearly_profitability_on
  #
  # @author Moisés Reis
  #
  # Calculates the percentage return for the current year. It ensures that
  # the starting balance is strictly the opening value of January 1st
  # to avoid interference from late-December transactions.
  #
  # Parameters::
  # - *date* - The current reference date for the dashboard.
  #
  # Returns::
  # - The percentage return as a rounded Float.

  def yearly_profitability_on(date)
    # Ensure we are looking at the start of the current calendar year
    start_of_year = date.beginning_of_year

    # The 'Opening Balance' of the year is the state of the portfolio
    # at the very end of the previous year.
    val_jan_1 = total_balance_on(start_of_year - 1.day)
    val_now = total_balance_on(date)

    return 0.0 if val_jan_1 <= 0

    # Calculation: ((Current / Start) - 1) * 100
    (((val_now / val_jan_1) - 1) * 100).to_f.round(2)
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

  # == estimated_current_month_earnings
  #
  # @author Moisés Reis
  #
  # Estimates earnings for the current in-progress month using the same
  # Modified Dietz logic as PerformanceCalculationJob, but reading live
  # quota valuations instead of relying on persisted performance_histories.
  #
  # Returns:: - Estimated earnings as a BigDecimal, or zero if data is insufficient.
  def estimated_current_month_earnings
    period_start = Date.current.beginning_of_month
    period_end = Date.current

    fund_investments.includes(:investment_fund, :applications, :redemptions).sum do |fi|
      fund = fi.investment_fund

      quota_start = closest_quota_value(fund.cnpj, period_start)
      quota_end = closest_quota_value(fund.cnpj, period_end)

      next BigDecimal("0") unless quota_start && quota_end

      quotas_at_start = reconstruct_quotas_at(fi, period_start - 1.day)
      quotas_at_end = reconstruct_quotas_at(fi, period_end)

      next BigDecimal("0") if quotas_at_start <= 0 && quotas_at_end <= 0

      initial_balance = quotas_at_start * quota_start
      final_balance = quotas_at_end * quota_end

      net_cash_flow = fi.applications.where(cotization_date: period_start..period_end).sum(:financial_value) -
                      fi.redemptions.where(cotization_date: period_start..period_end).sum(:redeemed_liquid_value)

      final_balance - initial_balance - net_cash_flow
    end
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
  # Calculates the portfolio monthly return using Modified Dietz (W=1).
  # The denominator is always the sum of initial_balance of continuing funds,
  # which equals IV + CF (opening balance plus net cash flows). Redeemed funds
  # had their capital leave the portfolio, so their initial_balance is excluded
  # from the denominator. For the most recent period (no next month exists),
  # all funds are treated as continuing and the full initial_balance is used.
  #
  # Parameters:: - *reference_date* - The period date for which to calculate the return.
  #
  # Returns:: - The calculated return percentage as a BigDecimal.
  def portfolio_return_percentage(reference_date = nil)
    target = reference_date&.to_date&.end_of_month ||
             performance_histories.maximum(:period)
    return BigDecimal("0") unless target

    perfs = performance_histories.where(period: target)
    return BigDecimal("0") if perfs.empty?

    total_earnings = perfs.sum(:earnings).to_d

    next_period      = target.next_month.end_of_month
    next_initial_sum = performance_histories
                         .where(period: next_period)
                         .sum(:initial_balance)
                         .to_d

    denominator = if next_initial_sum > 0
                    # Branch A: há dados do mês seguinte.
                    # Fundos resgatados somem automaticamente (EMV=0 → sem initial_balance em next_period).
                    next_initial_sum - total_earnings
                  else
                    # Branch B: período mais recente, sem next_month ainda.
                    # Pondera por EMV (Ending Market Value) de cada fundo.
                    # Fundos com resgate total têm EMV=0 e ficam de fora naturalmente,
                    # replicando o comportamento do Branch A sem depender de dados futuros.
                    total_emv = perfs.sum do |r|
                      fi = r.fund_investment
                      apps  = fi.applications.where("cotization_date <= ?", target).sum(:financial_value)
                      reds  = fi.redemptions.where("cotization_date <= ?", target).sum(:redeemed_liquid_value)
                      emv   = r.initial_balance.to_d + BigDecimal(apps.to_s) - BigDecimal(reds.to_s) + r.earnings.to_d
                      [emv, BigDecimal("0")].max
                    end

                    return BigDecimal("0") if total_emv.zero?

                    return perfs.sum do |r|
                      fi  = r.fund_investment
                      apps = fi.applications.where("cotization_date <= ?", target).sum(:financial_value)
                      reds = fi.redemptions.where("cotization_date <= ?", target).sum(:redeemed_liquid_value)
                      emv  = r.initial_balance.to_d + BigDecimal(apps.to_s) - BigDecimal(reds.to_s) + r.earnings.to_d
                      emv  = [emv, BigDecimal("0")].max

                      next BigDecimal("0") if emv.zero?

                      (emv / total_emv) * r.monthly_return.to_d
                    end
                  end

    return BigDecimal("0") if denominator.zero?

    (total_earnings / denominator) * 100
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

    weighted = BigDecimal("0")
    total_alloc = BigDecimal("0")

    perfs.group_by(&:fund_investment_id).each do |_, fund_perfs|
      fi = fund_perfs.first.fund_investment
      alloc = fi.percentage_allocation.to_d
      accumulated = fund_perfs.sum { |p| p.monthly_return.to_d }
      weighted += accumulated * alloc
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
      [month.strftime("%b/%y"), running_total]
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
      fund_name = fi.investment_fund.fund_name
      data[fund_name] = []
      running_quotas = 0

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

  # == yearly_earnings
  #
  # @author Moisés Reis
  #
  # Calculates the total earnings of the portfolio from the beginning of the
  # year up to the end of the month of the given reference date.
  #
  # Parameters:: *reference_date* - The date used to determine the year and month range.
  #                                 Defaults to Date.current.
  #
  # Returns:: - The sum of earnings as a Float, or 0.0 if no records are found.
  def yearly_earnings(reference_date = Date.current)
    beginning = reference_date.beginning_of_year
    ending = reference_date.end_of_month

    performance_histories
      .where(period: beginning..ending)
      .sum(:earnings)
      .to_f
  end

  # == monthly_earnings_history
  #
  # @author Moisés Reis
  #
  # Generates a chronological dataset of total earnings for each month of a specific year.
  # This method ensures every month is represented, defaulting to zero if no data exists.
  #
  # Parameters:: - year [Integer] - The calendar year to pull records for, defaulting to the current year.
  #
  # Returns:: - Array - A collection of pairs containing the formatted month name and its total earnings.
  def monthly_earnings_history(year = Date.current.year)

    # # Prepares an array of the first day of every month for the requested year.
    # # This acts as the skeleton to ensure no months are missing from the result.
    all_months = (1..12).map { |m| Date.new(year, m, 1) }

    # # Aggregates earnings by grouping performance records into their respective months.
    # # It calculates the sum of all earnings found within each monthly timeframe.
    earnings_by_month = performance_histories
                          .where(period: Date.new(year).beginning_of_year..Date.new(year).end_of_year)
                          .group_by { |ph| ph.period.beginning_of_month }
                          .transform_values { |phs| phs.sum(&:earnings) }

    # # Maps the full year of months to the calculated earnings or zero if empty.
    # # It formats the date into a short month/year string for chart display.
    all_months.map { |month| [month.strftime("%b/%y"), earnings_by_month[month] || 0] }
  end

  # == monthly_earnings
  #
  # @author Moisés Reis
  #
  # Calculates the total earnings of the portfolio within the month of the
  # given reference date, by summing the earnings field of all performance
  # history records whose period falls within that month.
  #
  # Parameters:: - *reference_date* - The date used to determine the month range.
  #                                   Defaults to Date.current.
  #
  # Returns:: - The sum of earnings as a Float, or 0.0 if no records are found.
  def monthly_earnings(reference_date = Date.current)
    performance_histories
      .where(period: reference_date.beginning_of_month..reference_date.end_of_month)
      .sum(:earnings)
      .to_f
  end

  private

  # == reconstruct_quotas_at
  #
  # @author Moisés Reis
  #
  # Calculates the net number of quotas held for a given fund investment
  # up to and including a specific date, by summing all applications and
  # subtracting all redemptions cotized on or before that date.
  #
  # Parameters:: - *fund_investment* - The FundInvestment record to calculate quotas for.
  #              - *date*            - The cutoff date for the quota reconstruction.
  #
  # Returns:: - The net quota balance as a BigDecimal.
  def reconstruct_quotas_at(fund_investment, date)
    apps = fund_investment.applications.where("cotization_date <= ?", date).sum(:number_of_quotas)
    reds = fund_investment.redemptions.where("cotization_date <= ?", date).sum(:redeemed_quotas)
    BigDecimal(apps.to_s) - BigDecimal(reds.to_s)
  end

  # == closest_quota_value
  #
  # @author Moisés Reis
  #
  # Attempts to retrieve the most recent quota value for a fund on or before
  # a specific date, excluding weekends. Uses a single SQL query ordered by
  # date descending instead of iterating day by day, which is more robust
  # against gaps caused by holidays or missing import runs.
  #
  # Parameters:: - *cnpj*        - The fund's CNPJ identifier.
  #              - *target_date* - The upper bound date for the quota valuation lookup.
  #
  # Returns:: - The quota value as a BigDecimal, or nil if no valuation is found.
  def closest_quota_value(cnpj, target_date)
    FundValuation
      .where(fund_cnpj: cnpj)
      .where("date <= ? AND EXTRACT(DOW FROM date) NOT IN (0, 6)", target_date)
      .order(date: :desc)
      .limit(1)
      .pluck(:quota_value)
      .first
  end
end

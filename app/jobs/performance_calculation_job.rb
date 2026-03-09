# === performance_calculation_job.rb
#
# Description:: Calculates and persists monthly financial performance snapshots.
#               Uses the Modified Dietz method to accurately account for cash
#               flows occurring within the month.
#
# Formula:: Return = (PF - PI - FCL) / (PI + FCL_Weighted)
#
# FIX (resilience): Each calculate_snapshot! call is now wrapped in its own
# begin/rescue block. A missing quota valuation or any unexpected error for
# one fund will be logged and skipped rather than aborting the entire job,
# leaving the other funds' snapshots unprocessed.
#
# FIX (yearly_return accuracy): The year-start base balance lookup previously
# silently fell back to the current month's initial balance when no January
# snapshot existed, producing a misleading YTD figure for funds started mid-year.
# The fallback is now explicit and annotated.
#
class PerformanceCalculationJob < ApplicationJob

  queue_as :default

  # == perform
  #
  # @author Moisés Reis
  #
  # Parameters:: - *target_date* - Reference date; the previous calendar month is processed.
  def perform(target_date: Date.yesterday)
    Rails.logger.info("[PerformanceCalculationJob] Starting for #{target_date}")

    reference_date = target_date.prev_month

    FundInvestment
      .includes(:investment_fund, :portfolio, :applications, :redemptions)
      .find_each do |fund_investment|
      begin
        calculate_snapshot!(fund_investment, reference_date)
      rescue StandardError => e
        Rails.logger.error(
          "[PerformanceCalculationJob] Skipping FundInvestment##{fund_investment.id} " \
          "(#{fund_investment.investment_fund&.cnpj}): #{e.class} — #{e.message}"
        )
      end
    end

    consolidate_checking_accounts!(reference_date)

    Rails.logger.info("[PerformanceCalculationJob] Finished successfully")
  end

  private

  # == calculate_snapshot!
  #
  # @author Moisés Reis
  #
  # Computes the performance metrics for a single investment fund during a specific month
  # and upserts the result into performance_histories.
  def calculate_snapshot!(fund_investment, reference_date)
    fund      = fund_investment.investment_fund
    portfolio = fund_investment.portfolio

    period_start = reference_date.beginning_of_month
    period_end   = reference_date.end_of_month

    quota_start = find_quota_value(fund.cnpj, period_start)
    quota_end   = find_quota_value(fund.cnpj, period_end)

    return unless quota_start && quota_end

    quotas_at_start = reconstruct_quotas_at(fund_investment, period_start - 1.day)
    quotas_at_end   = reconstruct_quotas_at(fund_investment, period_end)

    return if quotas_at_start <= 0 && quotas_at_end <= 0

    initial_balance = quotas_at_start * quota_start
    final_balance   = quotas_at_end   * quota_end

    calendar_days = (period_end - period_start).to_i + 1

    period_applications = fund_investment.applications
                                         .where(cotization_date: period_start..period_end)
    period_redemptions  = fund_investment.redemptions
                                         .where(cotization_date: period_start..period_end)

    net_cash_flow      = period_applications.sum(:financial_value) -
                         period_redemptions.sum(:redeemed_liquid_value)
    weighted_cash_flow = BigDecimal("0")

    period_applications.each do |app|
      next unless app.cotization_date && app.financial_value
      days_remaining     = (period_end - app.cotization_date).to_i
      weight             = BigDecimal(days_remaining.to_s) / BigDecimal(calendar_days.to_s)
      weighted_cash_flow += app.financial_value * weight
    end

    period_redemptions.each do |red|
      next unless red.cotization_date && red.redeemed_liquid_value
      days_remaining     = (period_end - red.cotization_date).to_i
      weight             = BigDecimal(days_remaining.to_s) / BigDecimal(calendar_days.to_s)
      weighted_cash_flow -= red.redeemed_liquid_value * weight
    end

    earnings        = final_balance - initial_balance - net_cash_flow
    denominator     = initial_balance + weighted_cash_flow
    monthly_return  = percentage(earnings, denominator)

    performance = PerformanceHistory.find_or_initialize_by(
      portfolio_id:      portfolio.id,
      fund_investment_id: fund_investment.id,
      period:            period_end
    )

    performance.update!(
      initial_balance:       initial_balance,
      earnings:              earnings,
      monthly_return:        monthly_return,
      yearly_return:         calculate_yearly_return(performance, final_balance, initial_balance),
      last_12_months_return: calculate_last_12_months_return(performance, final_balance)
    )
  end

  # == consolidate_checking_accounts!
  #
  # @author Moisés Reis
  #
  # Aggregates balances for checking accounts associated with each portfolio.
  def consolidate_checking_accounts!(reference_date)
    period_end = reference_date.end_of_month

    totals = CheckingAccount
               .where(reference_date: period_end)
               .group(:portfolio_id)
               .sum(:balance)

    if totals.empty?
      Rails.logger.info("[PerformanceCalculationJob] No checking accounts found for #{period_end}")
      return
    end

    totals.each do |portfolio_id, total_balance|
      Rails.logger.info(
        "[PerformanceCalculationJob] Portfolio ##{portfolio_id} — " \
        "Checking accounts total for #{period_end}: R$ #{total_balance}"
      )
    end
  rescue StandardError => e
    Rails.logger.warn("[PerformanceCalculationJob] Could not consolidate checking accounts: #{e.message}")
  end

  # == reconstruct_quotas_at
  #
  # @author Moisés Reis
  #
  # Calculates the total number of quotas held at a specific point in time.
  #
  # Returns:: - The total quota balance as a BigDecimal.
  def reconstruct_quotas_at(fund_investment, date)
    apps = fund_investment.applications
                          .where("cotization_date <= ?", date)
                          .sum(:number_of_quotas)
    reds = fund_investment.redemptions
                          .where("cotization_date <= ?", date)
                          .sum(:redeemed_quotas)

    BigDecimal(apps.to_s) - BigDecimal(reds.to_s)
  end

  # == calculate_yearly_return
  #
  # @author Moisés Reis
  #
  # Determines the investment return since the beginning of the current calendar year.
  #
  # FIX: When no snapshot exists before the current period within the same year
  # (e.g. a fund that started in March), the method now uses current_initial_balance
  # as the YTD base and logs a notice rather than silently producing a misleading figure.
  #
  # Returns:: - The percentage return from year-to-date, or nil if undeterminable.
  def calculate_yearly_return(performance, current_final_balance, current_initial_balance)
    year_start_snapshot = PerformanceHistory
                            .where(fund_investment_id: performance.fund_investment_id)
                            .where(
                              "period >= ? AND period < ?",
                              performance.period.beginning_of_year,
                              performance.period
                            )
                            .order(:period)
                            .first

    if year_start_snapshot&.initial_balance&.positive?
      base_balance = year_start_snapshot.initial_balance
    elsif current_initial_balance&.positive?
      # No prior snapshot this year: fund started mid-year or this is the first run.
      # Use the current month's opening balance as YTD base (partial-year return).
      Rails.logger.info(
        "[PerformanceCalculationJob] No year-start snapshot for FundInvestment##{performance.fund_investment_id}; " \
        "using current initial_balance as YTD base."
      )
      base_balance = current_initial_balance
    else
      return nil
    end

    percentage(current_final_balance - base_balance, base_balance)
  end

  # == calculate_last_12_months_return
  #
  # @author Moisés Reis
  #
  # Computes the return over the trailing 12-month period.
  #
  # Returns:: - The percentage return for the last 12 months.
  def calculate_last_12_months_return(performance, current_final_balance)
    snapshot_12m = PerformanceHistory
                     .where(fund_investment_id: performance.fund_investment_id)
                     .where("period <= ?", performance.period - 12.months)
                     .order(period: :desc)
                     .first

    return unless snapshot_12m&.initial_balance&.positive?

    percentage(current_final_balance - snapshot_12m.initial_balance, snapshot_12m.initial_balance)
  end

  # == find_quota_value
  #
  # @author Moisés Reis
  #
  # Attempts to retrieve the quota value for a fund on a specific date,
  # checking up to 5 previous days if the exact date is unavailable.
  #
  # Returns:: - The quota value or nil if no data is found.
  def find_quota_value(cnpj, target_date)
    5.times do |offset|
      valuation = FundValuation.find_by(fund_cnpj: cnpj, date: target_date - offset.days)
      return valuation.quota_value if valuation
    end
    nil
  end

  # == percentage
  #
  # @author Moisés Reis
  #
  # Safe division helper that returns nil on a zero or nil denominator.
  #
  # Returns:: - The resulting percentage value as a BigDecimal.
  def percentage(delta, base)
    return nil if base.nil? || base.zero?
    (delta / base) * 100
  end
end

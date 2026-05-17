# frozen_string_literal: true

# Service responsible for calculating the performance snapshot metrics for a
# specific FundInvestment and reference month.
#
# This calculator performs pure business logic only and does not persist data.
# It aggregates quota balances, period cash flows, and compounded return
# metrics used by performance reporting and historical analytics.
#
# @author Moisés Reis

module Shared
  class PerformanceSnapshotCalculator

    # =============================================================
    # RESULT STRUCTURE
    # =============================================================

    # Immutable result object containing all calculated performance metrics
    # for a single reference month.
    Result = Struct.new(
      :initial_balance,
      :final_balance,
      :earnings,
      :monthly_return,
      :yearly_return,
      :last_12_months_return,
      :quotas_at_start,
      :quotas_at_end,
      :quota_start,
      :quota_end,
      keyword_init: true
    )

    # =============================================================
    # CLASS METHODS
    # =============================================================

    class << self

      # Executes the performance snapshot calculation.
      #
      # @param fund_investment [FundInvestment] The investment being evaluated.
      # @param reference_date [Date, Time, DateTime] The month reference date.
      #
      # @return [Result, nil] The calculated snapshot metrics or nil when
      #   quota values are unavailable for the calculation period.
      #
      def call(fund_investment, reference_date)
        new(fund_investment, reference_date: reference_date).call
      end

    end

    # =============================================================
    # INITIALIZATION
    # =============================================================

    # Initializes the performance snapshot calculator.
    #
    # @param fund_investment [FundInvestment] The investment being evaluated.
    # @param reference_date [Date, Time, DateTime] The month reference date.
    #
    def initialize(fund_investment, reference_date:)
      @fund_investment = fund_investment
      @reference_date = reference_date.to_date
    end

    # =============================================================
    # PUBLIC METHODS
    # =============================================================

    # Calculates all performance snapshot metrics for the configured period.
    #
    # @return [Result, nil] The calculated snapshot metrics or nil when
    #   quota values are unavailable for the calculation period.
    #
    def call
      return unless quota_start && quota_end

      Result.new(
        initial_balance: initial_balance,
        final_balance: final_balance,
        earnings: earnings,
        monthly_return: monthly_return,
        yearly_return: calculate_yearly_return,
        last_12_months_return: calculate_last_12_months_return,
        quotas_at_start: quotas_at_start,
        quotas_at_end: quotas_at_end,
        quota_start: quota_start,
        quota_end: quota_end
      )
    end

    private

    # =============================================================
    # ATTRIBUTES
    # =============================================================

    # @!attribute [r] fund_investment
    #   @return [FundInvestment] The investment being evaluated.
    #
    # @!attribute [r] reference_date
    #   @return [Date] The normalized month reference date.
    #
    attr_reader :fund_investment, :reference_date

    # =============================================================
    # PERIOD BOUNDARIES
    # =============================================================

    # Returns the first day of the reference month.
    #
    # @return [Date] The beginning of the reference month.
    #
    def period_start
      @period_start ||= reference_date.beginning_of_month
    end

    # Returns the last day of the reference month.
    #
    # @return [Date] The end of the reference month.
    #
    def period_end
      @period_end ||= reference_date.end_of_month
    end

    # =============================================================
    # QUOTA RECONSTRUCTION
    # =============================================================

    # Reconstructs the quantity of quotas held before the reference month.
    #
    # @return [BigDecimal] The quota quantity held at the beginning of
    #   the calculation period.
    #
    def quotas_at_start
      @quotas_at_start ||= Shared::QuotaReconstructionCalculator.call(
        fund_investment: fund_investment,
        date: period_start - 1.day
      )
    end

    # Reconstructs the quantity of quotas held at the end of the
    # reference month.
    #
    # @return [BigDecimal] The quota quantity held at the end of the
    #   calculation period.
    #
    def quotas_at_end
      @quotas_at_end ||= Shared::QuotaReconstructionCalculator.call(
        fund_investment: fund_investment,
        date: period_end
      )
    end

    # =============================================================
    # PERIOD CASH FLOWS
    # =============================================================

    # Returns all applications cotized within the reference period.
    #
    # @return [ActiveRecord::Relation<Application>] The applications
    #   included in the calculation period.
    #
    def period_applications
      @period_applications ||= fund_investment.applications
                                              .where(cotization_date: period_start..period_end)
    end

    # Returns all redemptions cotized within the reference period.
    #
    # @return [ActiveRecord::Relation<Redemption>] The redemptions
    #   included in the calculation period.
    #
    def period_redemptions
      @period_redemptions ||= fund_investment.redemptions
                                             .where(cotization_date: period_start..period_end)
    end

    # Calculates the net cash flow for the reference month.
    #
    # Applications increase invested capital while redemptions reduce it.
    #
    # @return [BigDecimal] The net cash contribution during the period.
    #
    def net_cash_flow
      BigDecimal(period_applications.sum(:financial_value).to_s) -
        BigDecimal(period_redemptions.sum(:redeemed_liquid_value).to_s)
    end

    # =============================================================
    # BALANCE & EARNINGS CALCULATIONS
    # =============================================================

    # Calculates the investment earnings for the reference month.
    #
    # @return [BigDecimal] The net earnings excluding cash flow effects.
    #
    def earnings
      final_balance - initial_balance - net_cash_flow
    end

    # Calculates the portfolio balance at the start of the period.
    #
    # @return [BigDecimal] The initial investment balance.
    #
    def initial_balance
      quotas_at_start * quota_start
    end

    # Calculates the portfolio balance at the end of the period.
    #
    # @return [BigDecimal] The final investment balance.
    #
    def final_balance
      quotas_at_end * quota_end
    end

    # =============================================================
    # RETURN CALCULATIONS
    # =============================================================

    # Calculates the monthly quota return percentage.
    #
    # @return [BigDecimal, nil] The monthly percentage return or nil
    #   when the base quota value is invalid.
    #
    def monthly_return
      percentage(quota_end - quota_start, quota_start)
    end

    # Returns the quota value immediately before the reference month.
    #
    # @return [BigDecimal, nil] The starting quota value.
    #
    def quota_start
      @quota_start ||= quota_value_on(period_start - 1.day)
    end

    # Returns the quota value at the end of the reference month.
    #
    # @return [BigDecimal, nil] The ending quota value.
    #
    def quota_end
      @quota_end ||= quota_value_on(period_end)
    end

    # Calculates the compounded yearly return up to the reference month.
    #
    # @return [BigDecimal, nil] The compounded yearly return percentage.
    #
    def calculate_yearly_return
      return nil unless monthly_return

      year_start = period_start.beginning_of_year

      prior_returns = PerformanceHistory
                        .where(fund_investment_id: fund_investment.id)
                        .where('period >= ? AND period < ?', year_start, period_end)
                        .where.not(monthly_return: nil)
                        .order(:period)
                        .pluck(:monthly_return)

      return monthly_return if prior_returns.empty?

      compounded = prior_returns.reduce(BigDecimal('1')) do |acc, value|
        acc * (1 + BigDecimal(value.to_s) / 100)
      end

      compounded *= (1 + BigDecimal(monthly_return.to_s) / 100)

      (compounded - 1) * 100
    end

    # Calculates the compounded rolling 12-month return.
    #
    # @return [BigDecimal, nil] The rolling 12-month return percentage
    #   or nil when insufficient historical data exists.
    #
    def calculate_last_12_months_return
      return nil unless monthly_return

      window_start = period_end.prev_month(11)

      prior_returns = PerformanceHistory
                        .where(fund_investment_id: fund_investment.id)
                        .where('period >= ? AND period < ?', window_start, period_end)
                        .where.not(monthly_return: nil)
                        .order(:period)
                        .pluck(:monthly_return)

      return nil if prior_returns.size < 11

      compounded = prior_returns.reduce(BigDecimal('1')) do |acc, value|
        acc * (1 + BigDecimal(value.to_s) / 100)
      end

      compounded *= (1 + BigDecimal(monthly_return.to_s) / 100)

      (compounded - 1) * 100
    end

    # =============================================================
    # QUOTA VALUE HELPERS
    # =============================================================

    # Retrieves the investment fund quota value for a specific date.
    #
    # @param target_date [Date] The date used for quota lookup.
    #
    # @return [BigDecimal, nil] The quota value for the provided date.
    #
    def quota_value_on(target_date)
      fund_investment.investment_fund.quota_value_on(target_date)
    end

    # =============================================================
    # PERCENTAGE HELPERS
    # =============================================================

    # Calculates the percentage variation between a delta and base value.
    #
    # @param delta [Numeric] The variation amount.
    # @param base [Numeric] The comparison base value.
    #
    # @return [BigDecimal, nil] The calculated percentage or nil when
    #   the base value is invalid.
    #
    def percentage(delta, base)
      return nil if base.nil? || base.zero?

      BigDecimal(delta.to_s) / BigDecimal(base.to_s) * 100
    end

  end
end
# frozen_string_literal: true

# Calculates the Time-Weighted Return (TWR) for a portfolio
# between two dates.
#
# Reconstructs historical portfolio value day-by-day, neutralises
# external cash flows, and compounds daily performance to produce
# a time-weighted return percentage.
#
# @author Moisés Reis

module Portfolios

  class TwrCalculator

    # =============================================================
    #                         PUBLIC METHODS
    # =============================================================

    # Shortcut class method to instantiate and execute the calculator.
    #
    # @param portfolio [Portfolio] The portfolio being evaluated.
    # @param start_date [Date] Beginning of the calculation window.
    # @param end_date [Date] End of the calculation window.
    # @return [BigDecimal] The time-weighted return percentage.
    def self.call(portfolio, start_date:, end_date:)
      new(
        portfolio,
        start_date: start_date,
        end_date: end_date
      ).call
    end

    # =============================================================
    #                         INITIALIZATION
    # =============================================================

    # Initialises the TWR calculator with portfolio and date range.
    #
    # @param portfolio [Portfolio] The portfolio being evaluated.
    # @param start_date [Date] Beginning of the calculation window.
    # @param end_date [Date] End of the calculation window.
    def initialize(portfolio, start_date:, end_date:)
      @portfolio  = portfolio
      @start_date = start_date.to_date
      @end_date   = end_date.to_date
    end

    # =============================================================
    #                         PUBLIC METHODS
    # =============================================================

    # Executes the TWR calculation.
    #
    # @return [BigDecimal] The compounded time-weighted return.
    def call
      return BigDecimal("0") if fund_investments.empty?

      previous_close = portfolio_value_on(start_date)

      return BigDecimal("0") if previous_close <= 0

      compounded_factor = BigDecimal("1")

      (start_date + 1).upto(end_date) do |date|
        next if weekend?(date)

        day_close = portfolio_value_on(date)

        next if day_close <= 0

        day_cashflow = daily_cashflow_on(date)

        day_open = day_close - day_cashflow

        if day_open <= 0
          previous_close = day_close
          next
        end

        compounded_factor *= (day_open / previous_close)

        previous_close = day_close
      end

      (compounded_factor - 1) * 100
    end

    private

    # =============================================================
    #                          ATTRIBUTES
    # =============================================================

    attr_reader :portfolio,
                :start_date,
                :end_date

    # =============================================================
    #                       FUND INVESTMENTS
    # =============================================================

    # Returns all fund investments active during the calculation period.
    #
    # @return [Array<FundInvestment>]
    def fund_investments
      @fund_investments ||= portfolio
                              .fund_investments
                              .active_during(start_date, end_date)
                              .includes(:investment_fund)
                              .to_a
    end

    # Returns IDs of all active fund investments.
    #
    # @return [Array<Integer>]
    def fund_investment_ids
      @fund_investment_ids ||= fund_investments.map(&:id)
    end

    # Returns CNPJs of all active fund investments.
    #
    # @return [Array<String>]
    def fund_cnpjs
      @fund_cnpjs ||= fund_investments
                        .map { |fi| fi.investment_fund.cnpj }
                        .uniq
    end

    # =============================================================
    #                      CASH FLOW DATA
    # =============================================================

    # Returns applications grouped by fund investment.
    #
    # @return [Hash<Integer, Array<Hash>>]
    def applications_by_fi
      @applications_by_fi ||= Application
                                .where(fund_investment_id: fund_investment_ids)
                                .where("cotization_date <= ?", end_date)
                                .pluck(
                                  :fund_investment_id,
                                  :cotization_date,
                                  :number_of_quotas,
                                  :financial_value
                                )
                                .each_with_object(
                                  Hash.new { |h, k| h[k] = [] }
                                ) do |(fi_id, date, quotas, value), hash|
        hash[fi_id] << {
          date: date,
          quotas: BigDecimal(quotas.to_s),
          value: BigDecimal(value.to_s)
        }
      end
    end

    # Returns redemptions grouped by fund investment.
    #
    # @return [Hash<Integer, Array<Hash>>]
    def redemptions_by_fi
      @redemptions_by_fi ||= Redemption
                               .where(fund_investment_id: fund_investment_ids)
                               .where("cotization_date <= ?", end_date)
                               .pluck(
                                 :fund_investment_id,
                                 :cotization_date,
                                 :redeemed_quotas,
                                 :redeemed_liquid_value
                               )
                               .each_with_object(
                                 Hash.new { |h, k| h[k] = [] }
                               ) do |(fi_id, date, quotas, value), hash|
        hash[fi_id] << {
          date: date,
          quotas: BigDecimal(quotas.to_s),
          value: BigDecimal(value.to_s)
        }
      end
    end

    # =============================================================
    #                       VALUATION DATA
    # =============================================================

    # Returns fund valuations grouped by CNPJ.
    #
    # @return [Hash<String, Hash<Date, BigDecimal>>]
    def valuations_by_cnpj
      @valuations_by_cnpj ||= FundValuation
                                .where(fund_cnpj: fund_cnpjs)
                                .where(
                                  "date <= ? AND EXTRACT(DOW FROM date) NOT IN (0, 6)",
                                  end_date
                                )
                                .pluck(
                                  :fund_cnpj,
                                  :date,
                                  :quota_value
                                )
                                .each_with_object(
                                  Hash.new { |h, k| h[k] = {} }
                                ) do |(cnpj, date, value), hash|
        hash[cnpj][date] = BigDecimal(value.to_s)
      end
    end

    # =============================================================
    #                      QUOTA HELPERS
    # =============================================================

    # Calculates net quota balance for a fund investment on a date.
    #
    # @param fi_id [Integer] Fund investment ID.
    # @param date [Date] Target date.
    # @return [BigDecimal] Net quota count.
    def quotas_on(fi_id, date)
      applications =
        applications_by_fi[fi_id]
          .select { |app| app[:date] <= date }
          .sum { |app| app[:quotas] }

      redemptions =
        redemptions_by_fi[fi_id]
          .select { |red| red[:date] <= date }
          .sum { |red| red[:quotas] }

      BigDecimal(applications.to_s) - BigDecimal(redemptions.to_s)
    end

    # Looks up the quota price for a CNPJ on or before a date.
    #
    # @param cnpj [String] Fund CNPJ.
    # @param date [Date] Target date.
    # @return [BigDecimal, nil] Quota price or nil if unavailable.
    def quota_price_on(cnpj, date)
      dates = valuations_by_cnpj[cnpj]

      return nil if dates.blank?

      closest_date =
        dates.keys
             .select { |d| d <= date }
             .max

      closest_date ? dates[closest_date] : nil
    end

    # =============================================================
    #                     PORTFOLIO VALUATION
    # =============================================================

    # Calculates total portfolio value on a given date.
    #
    # @param date [Date] Target date.
    # @return [BigDecimal] Portfolio value.
    def portfolio_value_on(date)
      fund_investments.sum do |fi|
        quotas = quotas_on(fi.id, date)

        next BigDecimal("0") if quotas <= 0

        price = quota_price_on(fi.investment_fund.cnpj, date)

        next BigDecimal("0") unless price

        quotas * price
      end
    end

    # Calculates net daily cash flow for the portfolio.
    #
    # @param date [Date] Target date.
    # @return [BigDecimal] Net cash flow value.
    def daily_cashflow_on(date)
      fund_investments.sum do |fi|
        applications =
          applications_by_fi[fi.id]
            .select { |app| app[:date] == date }
            .sum { |app| app[:value] }

        redemptions =
          redemptions_by_fi[fi.id]
            .select { |red| red[:date] == date }
            .sum { |red| red[:value] }

        applications - redemptions
      end
    end

    # =============================================================
    #                         HELPERS
    # =============================================================

    # Checks whether a date falls on a weekend.
    #
    # @param date [Date] Target date.
    # @return [Boolean] True if Saturday or Sunday.
    def weekend?(date)
      date.saturday? || date.sunday?
    end
  end
end
# frozen_string_literal: true

# app/calculators/portfolios/twr_calculator.rb

module Portfolios
  ##
  # Calculates the Time-Weighted Return (TWR) for a portfolio
  # between two dates.
  #
  # The calculation:
  # - reconstructs historical portfolio value day-by-day
  # - neutralizes external cashflows
  # - compounds daily performance
  #
  class TwrCalculator

    ##
    # @param portfolio [Portfolio]
    # @param start_date [Date]
    # @param end_date [Date]
    #
    # @return [BigDecimal]
    #
    def self.call(portfolio, start_date:, end_date:)
      new(
        portfolio,
        start_date: start_date,
        end_date: end_date
      ).call
    end

    ##
    # @param portfolio [Portfolio]
    # @param start_date [Date]
    # @param end_date [Date]
    #
    def initialize(portfolio, start_date:, end_date:)
      @portfolio  = portfolio
      @start_date = start_date.to_date
      @end_date   = end_date.to_date
    end

    ##
    # @return [BigDecimal]
    #
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

        next if day_open <= 0

        compounded_factor *= (day_open / previous_close)

        previous_close = day_close
      end

      (compounded_factor - 1) * 100
    end

    private

    attr_reader :portfolio,
                :start_date,
                :end_date

    ##
    # @return [Array<FundInvestment>]
    #
    def fund_investments
      @fund_investments ||= portfolio
                              .fund_investments
                              .includes(:investment_fund)
                              .to_a
    end

    ##
    # @return [Array<Integer>]
    #
    def fund_investment_ids
      @fund_investment_ids ||= fund_investments.map(&:id)
    end

    ##
    # @return [Array<String>]
    #
    def fund_cnpjs
      @fund_cnpjs ||= fund_investments
                        .map { |fi| fi.investment_fund.cnpj }
                        .uniq
    end

    ##
    # @return [Hash]
    #
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

    ##
    # @return [Hash]
    #
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

    ##
    # @return [Hash]
    #
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

    ##
    # @param fi_id [Integer]
    # @param date [Date]
    #
    # @return [BigDecimal]
    #
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

    ##
    # @param cnpj [String]
    # @param date [Date]
    #
    # @return [BigDecimal, nil]
    #
    def quota_price_on(cnpj, date)
      dates = valuations_by_cnpj[cnpj]

      return nil if dates.blank?

      closest_date =
        dates.keys
             .select { |d| d <= date }
             .max

      closest_date ? dates[closest_date] : nil
    end

    ##
    # @param date [Date]
    #
    # @return [BigDecimal]
    #
    def portfolio_value_on(date)
      fund_investments.sum do |fi|
        quotas = quotas_on(fi.id, date)

        next BigDecimal("0") if quotas <= 0

        price = quota_price_on(fi.investment_fund.cnpj, date)

        next BigDecimal("0") unless price

        quotas * price
      end
    end

    ##
    # @param date [Date]
    #
    # @return [BigDecimal]
    #
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

    ##
    # @param date [Date]
    #
    # @return [Boolean]
    #
    def weekend?(date)
      date.saturday? || date.sunday?
    end
  end
end
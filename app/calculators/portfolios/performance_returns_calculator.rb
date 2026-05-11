# app/calculators/portfolios/performance_returns_calculator.rb
#
# Computes total earnings, weighted portfolio return, and weighted 12-month
# return from a set of PerformanceHistory records.
module Portfolios
  class PerformanceReturnsCalculator
    Result = Struct.new(:total_earnings, :portfolio_return, :portfolio_12m_return, keyword_init: true)

    ZERO = BigDecimal("0")

    def self.call(recent_performance, reference_date)
      new(recent_performance, reference_date).call
    end

    def initialize(recent_performance, reference_date)
      @recent_performance = recent_performance
      @reference_date     = reference_date
    end

    def call
      return empty_result if @recent_performance.none?

      active    = active_performance
      total_initial = active.sum { |p| effective_balance(p) }
      total_earnings = active.sum(&:earnings)

      return empty_result.tap { |r| r.total_earnings = total_earnings } unless total_initial > 0

      portfolio_return = (total_earnings / total_initial) * 100
      portfolio_12m    = active.sum do |perf|
        (effective_balance(perf) / total_initial) * (perf.last_12_months_return || 0)
      end

      Result.new(
        total_earnings:    total_earnings,
        portfolio_return:  portfolio_return,
        portfolio_12m_return: portfolio_12m
      )
    end

    private

    def active_performance
      period = @reference_date.end_of_month

      fi_ids = @recent_performance.map(&:fund_investment_id).uniq
      return @recent_performance if fi_ids.empty?

      net_quotas = lambda do |date|
        apps = Application.where(fund_investment_id: fi_ids)
                          .where("cotization_date <= ?", date)
                          .group(:fund_investment_id)
                          .sum(:number_of_quotas)
        reds = Redemption.where(fund_investment_id: fi_ids)
                         .where("cotization_date <= ?", date)
                         .group(:fund_investment_id)
                         .sum(:redeemed_quotas)
        fi_ids.index_with { |id| apps[id].to_d - reds[id].to_d }
      end

      net_at_reference = net_quotas.call(@reference_date)
      net_at_period    = net_quotas.call(period)

      @recent_performance.select do |perf|
        fi = perf.fund_investment
        quota = fi.investment_fund.quota_value_on(@reference_date)
        market_value = quota ? net_at_reference[fi.id] * BigDecimal(quota.to_s) : BigDecimal("0")
        market_value > 0 || net_at_period[fi.id] > 0
      end
    end

    def effective_balance(perf)
      if perf.initial_balance&.positive?
        perf.initial_balance
      elsif perf.monthly_return&.nonzero? && perf.earnings
        (perf.earnings / (perf.monthly_return / BigDecimal("100"))).abs
      else
        ZERO
      end
    end

    def empty_result
      Result.new(total_earnings: ZERO, portfolio_return: ZERO, portfolio_12m_return: ZERO)
    end
  end
end
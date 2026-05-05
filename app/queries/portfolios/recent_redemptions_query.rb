# app/queries/portfolios/recent_redemptions_query.rb
#
# Returns the most recent redemptions for a given portfolio.
#
# Replaces the in-memory chain:
#   fund_investments.includes(:redemptions).flat_map(&:redemptions)
#     .select { |red| red.request_date&.year == Date.current.year }
#     .sort_by(&:request_date).reverse.first(5)
#
# A single SQL query with a JOIN avoids loading all redemptions into
# memory and eliminates the N+1 caused by iterating fund_investments.
#
# @author Moisés Reis
module Portfolios
  class RecentRedemptionsQuery

    # =============================================================
    #                      1. PUBLIC INTERFACE
    # =============================================================

    # @param portfolio [Portfolio] The portfolio whose redemptions to retrieve.
    # @param limit     [Integer]   Maximum number of records to return (default: 5).
    # @return [ActiveRecord::Relation<Redemption>]
    def self.call(portfolio, limit: 5)
      new(portfolio, limit).call
    end

    # =============================================================
    #                        2. INITIALIZATION
    # =============================================================

    # @param portfolio [Portfolio]
    # @param limit     [Integer]
    def initialize(portfolio, limit)
      @portfolio = portfolio
      @limit     = limit
    end

    # =============================================================
    #                      3. QUERY EXECUTION
    # =============================================================

    # @return [ActiveRecord::Relation<Redemption>]
    def call
      Redemption
        .joins(:fund_investment)
        .where(fund_investments: { portfolio_id: @portfolio.id })
        .where("EXTRACT(YEAR FROM request_date) = ?", Date.current.year)
        .includes(fund_investment: :investment_fund)
        .order(request_date: :desc)
        .limit(@limit)
    end
  end
end
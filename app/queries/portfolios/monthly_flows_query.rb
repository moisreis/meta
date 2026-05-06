# app/queries/portfolios/monthly_flows_query.rb
#
# Returns monthly application and redemption totals for the current year,
# formatted for chartkick column chart rendering.
module Portfolios
  class MonthlyFlowsQuery
    def self.call(portfolio)
      new(portfolio).call
    end

    def initialize(portfolio)
      @portfolio = portfolio
    end

    def call
      [
        { name: "Aplicações", data: monthly_data.map { |m| [m[:month], m[:applications]] } },
        { name: "Resgates",   data: monthly_data.map { |m| [m[:month], m[:redemptions]]  } }
      ]
    end

    private

    def monthly_data
      @monthly_data ||= (1..12).map do |month_num|
        month_start = Date.new(Date.current.year, month_num, 1)
        month_end   = month_start.end_of_month

        {
          month:        month_start.strftime("%b/%y"),
          applications: Application.joins(:fund_investment)
                                   .where(fund_investments: { portfolio_id: @portfolio.id })
                                   .where(cotization_date: month_start..month_end)
                                   .sum(:financial_value),
          redemptions:  Redemption.joins(:fund_investment)
                                  .where(fund_investments: { portfolio_id: @portfolio.id })
                                  .where(cotization_date: month_start..month_end)
                                  .sum(:redeemed_liquid_value)
        }
      end
    end
  end
end
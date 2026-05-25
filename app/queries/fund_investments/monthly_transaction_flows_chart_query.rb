# frozen_string_literal: true

module FundInvestments

  # Queries monthly transaction flow data for chart rendering.
  #
  # This query aggregates application and redemption values grouped
  # by month, producing a Chartkick-compatible grouped column chart
  # dataset.
  #
  # @author Moisés Reis  
  class MonthlyTransactionFlowsChartQuery

    # =============================================================
    #                        PUBLIC METHODS
    # =============================================================

    # Builds monthly grouped transaction flow data.
    #
    # @param fund_investment [FundInvestment] Target investment entity.
    #
    # @return [Hash<String, Hash<String, Numeric>>] Chronologically
    #   ordered grouped dataset.
    def self.call(fund_investment)
      applications = applications_by_month(fund_investment)
      redemptions  = redemptions_by_month(fund_investment)

      months = (applications.keys + redemptions.keys).uniq.sort

      months.index_with do |month|
        {
          "Aplicações" => applications[month] || 0,
          "Resgates"   => redemptions[month] || 0
        }
      end
    end

    # =============================================================
    #                       PRIVATE METHODS
    # =============================================================

    private_class_method

    # Aggregates applications grouped by month.
    #
    # @param fund_investment [FundInvestment]
    #
    # @return [Hash<String, BigDecimal>]
    def self.applications_by_month(fund_investment)
      fund_investment
        .applications
        .group(
          Arel.sql(
            "TO_CHAR(request_date, 'MM/YYYY')"
          )
        )
        .order(
          Arel.sql(
            "MIN(request_date)"
          )
        )
        .sum(:financial_value)
    end

    # Aggregates redemptions grouped by month.
    #
    # @param fund_investment [FundInvestment]
    #
    # @return [Hash<String, BigDecimal>]
    def self.redemptions_by_month(fund_investment)
      fund_investment
        .redemptions
        .group(
          Arel.sql(
            "TO_CHAR(request_date, 'MM/YYYY')"
          )
        )
        .order(
          Arel.sql(
            "MIN(request_date)"
          )
        )
        .sum(:redeemed_liquid_value)
    end
  end
end

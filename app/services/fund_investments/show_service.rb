# Assembles all data required to render the fund investment
# details page.
#
# This service centralizes all queries, aggregations,
# chart datasets, and financial calculations necessary
# to build the visualization payload for a single
# {FundInvestment}.
#
# This service does NOT implement persistence logic
# or controller response behavior.
#
# Follows the Result + thin-call service pattern.
#
# @author Moisés Reis

module FundInvestments
  class ShowService

    # =============================================================
    #                         RESULT OBJECT
    # =============================================================

    # Immutable result object returned by the
    # FundInvestment show visualization workflow.
    #
    # @!attribute [r] fund_investment
    #   @return [FundInvestment]
    #   Investment being visualized.
    #
    # @!attribute [r] reference_date
    #   @return [Date]
    #   Reference date used for financial calculations.
    #
    # @!attribute [r] current_market_value
    #   @return [BigDecimal]
    #   Current reconstructed market value.
    #
    # @!attribute [r] unrealized_gain_loss
    #   @return [BigDecimal]
    #   Unrealized investment gain or loss.
    #
    # @!attribute [r] total_applications
    #   @return [BigDecimal]
    #   Aggregated investment application value.
    #
    # @!attribute [r] total_redemptions
    #   @return [BigDecimal]
    #   Aggregated redemption value.
    #
    # @!attribute [r] total_gain
    #   @return [BigDecimal]
    #   Total investment profitability.
    #
    # @!attribute [r] return_percentage
    #   @return [BigDecimal]
    #   Percentage investment return.
    #
    # @!attribute [r] monthly_transaction_flows_chart
    #   @return [Hash]
    #   Dataset for monthly transaction flow charts.
    #
    # @!attribute [r] transaction_distribution_chart
    #   @return [Hash]
    #   Dataset for transaction distribution charts.
    #
    # @!attribute [r] applications
    #   @return [ActiveRecord::Relation<Application>]
    #   Ordered application collection.
    #
    # @!attribute [r] redemptions
    #   @return [ActiveRecord::Relation<Redemption>]
    #   Ordered redemption collection.
    #
    # @!attribute [r] performance_histories
    #   @return [ActiveRecord::Relation<PerformanceHistory>]
    #   Historical performance records.
    Result = Struct.new(
      :fund_investment,
      :reference_date,
      :current_market_value,
      :unrealized_gain_loss,
      :total_applications,
      :total_redemptions,
      :total_gain,
      :return_percentage,
      :monthly_transaction_flows_chart,
      :transaction_distribution_chart,
      :applications,
      :redemptions,
      :performance_histories,
      keyword_init: true
    )

    private_class_method :new

    # =============================================================
    #                      PUBLIC INTERFACE
    # =============================================================

    # Builds the complete visualization payload for
    # a fund investment details page.
    #
    # @param fund_investment [FundInvestment]
    #   Investment being analyzed.
    #
    # @param reference_date [Date]
    #   Reference date used for calculations.
    #
    # @return [Result]
    #   Fully-populated visualization result object.
    def self.call(fund_investment, reference_date:)
      new(fund_investment, reference_date).send(:call)
    end

    # =============================================================
    #                        INITIALIZATION
    # =============================================================

    private

    # Initializes the visualization workflow context.
    #
    # @param fund_investment [FundInvestment]
    #   Investment being analyzed.
    #
    # @param reference_date [Date]
    #   Reference date used for calculations.
    #
    # @return [void]
    def initialize(fund_investment, reference_date)
      @fund_investment = fund_investment
      @reference_date = reference_date
    end

    # =============================================================
    #                           EXECUTION
    # =============================================================

    # Builds the complete result object.
    #
    # @return [Result]
    #   Aggregated visualization payload.
    def call
      Result.new(
        fund_investment: @fund_investment,
        reference_date: @reference_date,
        **financial_fields,
        **chart_fields,
        **collection_fields
      )
    end

    # =============================================================
    #                    MEMOIZED INTERMEDIATES
    # =============================================================

    # --- CURRENT MARKET VALUE -----------------------------------

    # Returns the reconstructed current market value.
    #
    # @return [BigDecimal]
    #   Current market valuation.
    def current_market_value
      @current_market_value ||=
        FundInvestments::CurrentMarketValueQuery.call(
          @fund_investment,
          @reference_date
        )
    end

    # --- UNREALIZED GAIN / LOSS ---------------------------------

    # Returns the unrealized gain or loss value.
    #
    # @return [BigDecimal]
    #   Unrealized profitability result.
    def unrealized_gain_loss
      @unrealized_gain_loss ||=
        FundInvestments::UnrealizedGainLossQuery.call(
          @fund_investment,
          @reference_date
        )
    end

    # --- TOTAL APPLICATIONS -------------------------------------

    # Returns the aggregated application amount.
    #
    # @return [BigDecimal]
    #   Total application value.
    def total_applications
      @total_applications ||=
        FundInvestments::TotalApplicationsQuery.call(
          @fund_investment
        )
    end

    # --- TOTAL REDEMPTIONS --------------------------------------

    # Returns the aggregated redemption amount.
    #
    # @return [BigDecimal]
    #   Total redeemed value.
    def total_redemptions
      @total_redemptions ||=
        FundInvestments::TotalRedemptionsQuery.call(
          @fund_investment
        )
    end

    # --- TOTAL GAIN ---------------------------------------------

    # Returns the total profitability result.
    #
    # @return [BigDecimal]
    #   Total investment gain.
    def total_gain
      @total_gain ||=
        FundInvestments::TotalGainQuery.call(
          @fund_investment,
          @reference_date
        )
    end

    # --- RETURN PERCENTAGE --------------------------------------

    # Returns the percentage return for the investment.
    #
    # @return [BigDecimal]
    #   Investment return percentage.
    def return_percentage
      @return_percentage ||=
        FundInvestments::ReturnPercentageQuery.call(
          @fund_investment,
          @reference_date
        )
    end

    # --- MONTHLY TRANSACTION FLOWS CHART ------------------------

    # Returns the monthly transaction flow chart dataset.
    #
    # @return [Hash]
    #   Monthly chart visualization dataset.
    def monthly_transaction_flows_chart
      @monthly_transaction_flows_chart ||=
        FundInvestments::MonthlyTransactionFlowsChartQuery.call(
          @fund_investment
        )
    end

    # --- TRANSACTION DISTRIBUTION CHART -------------------------

    # Returns the transaction distribution chart dataset.
    #
    # @return [Hash]
    #   Distribution chart visualization dataset.
    def transaction_distribution_chart
      @transaction_distribution_chart ||=
        FundInvestments::TransactionDistributionChartQuery.call(
          @fund_investment
        )
    end

    # --- APPLICATIONS -------------------------------------------

    # Returns ordered application records.
    #
    # @return [ActiveRecord::Relation<Application>]
    #   Ordered application collection.
    def applications
      @applications ||=
        FundInvestments::ApplicationsQuery.call(
          @fund_investment
        )
    end

    # --- REDEMPTIONS --------------------------------------------

    # Returns ordered redemption records.
    #
    # @return [ActiveRecord::Relation<Redemption>]
    #   Ordered redemption collection.
    def redemptions
      @redemptions ||=
        FundInvestments::RedemptionsQuery.call(
          @fund_investment
        )
    end

    # --- PERFORMANCE HISTORIES ----------------------------------

    # Returns recent historical performance records.
    #
    # @return [ActiveRecord::Relation<PerformanceHistory>]
    #   Ordered performance history collection.
    def performance_histories
      @performance_histories ||=
        FundInvestments::PerformanceHistoriesQuery.call(
          @fund_investment
        )
    end

    # =============================================================
    #                    RESULT FIELD BUILDERS
    # =============================================================

    # --- FINANCIAL FIELDS ---------------------------------------

    # Builds valuation-related result fields.
    #
    # @return [Hash]
    #   Financial result payload.
    def financial_fields
      {
        current_market_value: current_market_value,
        unrealized_gain_loss: unrealized_gain_loss,
        total_applications: total_applications,
        total_redemptions: total_redemptions,
        total_gain: total_gain,
        return_percentage: return_percentage
      }
    end

    # --- CHART FIELDS -------------------------------------------

    # Builds chart-related result fields.
    #
    # @return [Hash]
    #   Chart visualization payload.
    def chart_fields
      {
        monthly_transaction_flows_chart:
          monthly_transaction_flows_chart,

        transaction_distribution_chart:
          transaction_distribution_chart
      }
    end

    # --- COLLECTION FIELDS --------------------------------------

    # Builds collection-related result fields.
    #
    # @return [Hash]
    #   Transaction and performance collections.
    def collection_fields
      {
        applications: applications,
        redemptions: redemptions,
        performance_histories: performance_histories
      }
    end
  end
end
# frozen_string_literal: true

module FundInvestments

  # Queries recent performance history records for a fund investment.
  #
  # Retrieves the latest generated performance snapshots ordered by
  # creation date in descending order, limited to the most recent
  # entries displayed in the UI.
  #
  # @author Moisés Reis  
  class PerformanceHistoriesQuery

    # =============================================================
    #                        PUBLIC METHODS
    # =============================================================

    # Returns recent ordered performance history records.
    #
    # @param fund_investment [FundInvestment] Target investment entity.
    #
    # @return [ActiveRecord::Relation<PerformanceHistory>]
    def self.call(fund_investment)
      fund_investment
        .performance_histories
        .order(created_at: :desc)
        .limit(10)
    end
  end
end

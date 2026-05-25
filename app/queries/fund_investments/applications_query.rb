# frozen_string_literal: true

module FundInvestments

  # Queries ordered application records for a fund investment.
  #
  # Retrieves all applications sorted by request date in descending
  # order, allowing the most recent operations to appear first in
  # the UI
  #
  # @author Moisés Reis  
  class ApplicationsQuery

    # =============================================================
    #                        PUBLIC METHODS
    # =============================================================

    # Returns ordered application records.
    #
    # @param fund_investment [FundInvestment] Target investment entity.
    #
    # @return [ActiveRecord::Relation<Application>]
    def self.call(fund_investment)
      fund_investment
        .applications
        .order(request_date: :desc)
    end
  end
end

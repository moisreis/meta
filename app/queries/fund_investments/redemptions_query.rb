# frozen_string_literal: true

module FundInvestments

  # Queries ordered redemption records for a fund investment.
  #
  # Retrieves all redemptions sorted by request date in descending
  # order, allowing the most recent operations to appear first in
  # the UI.
  #
  # @author Moisés Reis  
  class RedemptionsQuery

    # =============================================================
    #                        PUBLIC METHODS
    # =============================================================

    # Returns ordered redemption records.
    #
    # @param fund_investment [FundInvestment] Target investment entity.
    #
    # @return [ActiveRecord::Relation<Redemption>]
    def self.call(fund_investment)
      fund_investment
        .redemptions
        .order(request_date: :desc)
    end
  end
end

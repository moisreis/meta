# frozen_string_literal: true

# Returns checking accounts for a portfolio, ordered by reference date
# descending.
#
# @author Moisés Reis

module Portfolios
  class CheckingAccountsQuery

    def self.call(portfolio)
      new(portfolio).call
    end

    def initialize(portfolio)
      @portfolio = portfolio
    end

    def call
      @portfolio.checking_accounts
                .order(reference_date: :desc)
    end

  end
end

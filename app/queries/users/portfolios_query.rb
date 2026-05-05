# frozen_string_literal: true

# app/queries/users/portfolios_query.rb
#
# Returns all portfolios associated with a user while
# preloading aggregated portfolio metrics at the database level.
#
# @example
#   portfolios = Users::PortfoliosQuery.call(user)
#
#   portfolios.each do |portfolio|
#     portfolio.fund_investments_count
#     portfolio.total_invested_value
#     portfolio.total_percentage_allocation
#   end
#
# @author Moisés Reis
module Users
  class PortfoliosQuery

    # ===========================================================
    #                         1. ENTRYPOINT
    # ===========================================================

    # Executes the portfolio aggregation query.
    #
    # @param user [User]
    #
    # @return [ActiveRecord::Relation<Portfolio>]
    def self.call(user)
      new(user: user).call
    end

    # ===========================================================
    #                      2. INITIALIZATION
    # ===========================================================

    # Initializes the query state.
    #
    # @param user [User]
    #
    # @return [void]
    def initialize(user:)
      @user = user
    end

    # ===========================================================
    #                        3. QUERY WORKFLOW
    # ===========================================================

    # Loads user portfolios with aggregated investment metrics.
    #
    # @return [ActiveRecord::Relation<Portfolio>]
    def call
      @user
        .portfolios
        .left_joins(:fund_investments)
        .select(
          "portfolios.*",
          "COUNT(fund_investments.id) AS fund_investments_count",
          "COALESCE(SUM(fund_investments.total_invested_value), 0) AS total_invested_value",
          "COALESCE(SUM(fund_investments.percentage_allocation), 0) AS total_percentage_allocation"
        )
        .group("portfolios.id")
    end
  end
end
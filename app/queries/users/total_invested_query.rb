# frozen_string_literal: true

# app/queries/users/total_invested_query.rb
#
# Calculates the aggregate invested value across all fund
# investments associated with a user's portfolios.
#
# This query performs the aggregation directly in the database
# to avoid unnecessary Active Record object loading.
#
# @example
#   total_invested = Users::TotalInvestedQuery.call(user)
#
#   total_invested
#   # => BigDecimal
#
# @author Moisés Reis
module Users
  class TotalInvestedQuery
    # ===========================================================
    #                         1. ENTRYPOINT
    # ===========================================================

    # Executes the query.
    #
    # @param user [User]
    # @return [BigDecimal]
    def self.call(user)
      new(user).call
    end

    private

    # ===========================================================
    #                        2. INITIALIZATION
    # ===========================================================

    # @param user [User]
    def initialize(user)
      @user = user
    end

    # ===========================================================
    #                           3. QUERY
    # ===========================================================

    # Returns the total invested value across all portfolios
    # owned by the user.
    #
    # @return [BigDecimal]
    def call
      FundInvestment
        .joins(:portfolio)
        .where(portfolios: { user_id: @user.id })
        .sum(:total_invested_value)
    end
  end
end
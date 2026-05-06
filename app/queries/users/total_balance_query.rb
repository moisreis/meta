# frozen_string_literal: true

# app/queries/users/total_balance_query.rb
#
# Calculates the aggregate checking account balance across all
# portfolios belonging to a specific user.
#
# This query performs the aggregation directly at the database
# level to avoid loading account records into memory.
#
# @example
#   total_balance = Users::TotalBalanceQuery.call(user)
#
#   total_balance
#   # => BigDecimal
#
# @author Moisés Reis
module Users
  class TotalBalanceQuery

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

    public

    # ===========================================================
    #                           3. QUERY
    # ===========================================================

    # Returns the sum of all checking account balances associated
    # with the user's portfolios.
    #
    # @return [BigDecimal]
    def call
      CheckingAccount
        .joins(:portfolio)
        .where(portfolios: { user_id: @user.id })
        .sum(:balance)
    end
  end
end
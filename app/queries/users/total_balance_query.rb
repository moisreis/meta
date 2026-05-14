# Provides user-related query objects and data access operations.
#
# This namespace groups query services responsible for encapsulating
# user-specific database querying and reporting logic.
#
# @author Moisés Reis

module Users

  # Calculates the total checking account balance for a user.
  #
  # This query object aggregates balances across all checking accounts
  # associated with portfolios owned by the specified user.
  class TotalBalanceQuery

    # ==========================================================================
    # PUBLIC CLASS METHODS
    # ==========================================================================

    class << self

      # Executes the query object.
      #
      # @param user [User] User whose total balance will be calculated.
      # @return [BigDecimal] Sum of all associated checking account balances.
      def call(user)
        new(user: user).call
      end
    end

    # ==========================================================================
    # INITIALIZATION
    # ==========================================================================

    # Initializes the query object.
    #
    # @param user [User] User whose total balance will be calculated.
    def initialize(user:)
      @user = user
    end

    # ==========================================================================
    # PUBLIC METHODS
    # ==========================================================================

    # Calculates the total balance across all user checking accounts.
    #
    # The query traverses portfolio ownership to ensure balances are limited
    # to accounts associated with the specified user.
    #
    # @return [BigDecimal] Sum of all associated checking account balances.
    def call
      CheckingAccount
        .joins(:portfolio)
        .where(portfolios: { user_id: @user.id })
        .sum(:balance)
    end
  end
end

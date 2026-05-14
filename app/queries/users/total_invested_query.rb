# Provides user-related query objects and data access operations.
#
# This namespace groups query services responsible for encapsulating
# user-specific database querying and reporting logic.
#
# @author Moisés Reis

module Users

  # Calculates the total invested value for a user.
  #
  # This query object aggregates investment totals across all fund investments
  # associated with portfolios owned by the specified user.
  class TotalInvestedQuery

    # ==========================================================================
    # PUBLIC CLASS METHODS
    # ==========================================================================

    class << self

      # Executes the query object.
      #
      # @param user [User] User whose total invested value will be calculated.
      # @return [BigDecimal] Sum of all associated invested values.
      def call(user)
        new(user: user).call
      end
    end

    # ==========================================================================
    # INITIALIZATION
    # ==========================================================================

    # Initializes the query object.
    #
    # @param user [User] User whose total invested value will be calculated.
    def initialize(user:)
      @user = user
    end

    # ==========================================================================
    # PUBLIC METHODS
    # ==========================================================================

    # Calculates the total invested value across all user fund investments.
    #
    # The query traverses portfolio ownership to ensure investment totals
    # are restricted to records associated with the specified user.
    #
    # @return [BigDecimal] Sum of all associated invested values.
    def call
      FundInvestment
        .joins(:portfolio)
        .where(portfolios: { user_id: @user.id })
        .sum(:total_invested_value)
    end
  end
end

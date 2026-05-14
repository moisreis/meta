# Provides user-related query objects and data access operations.
#
# This namespace groups query services responsible for encapsulating
# user-specific database querying and reporting logic.
#
# @author Moisés Reis

module Users

  # Builds aggregated portfolio data for a user.
  #
  # This query object retrieves portfolios associated with a user and
  # calculates investment-related aggregate metrics used for reporting
  # and dashboard presentation.
  class PortfoliosQuery

    # ==========================================================================
    # PUBLIC CLASS METHODS
    # ==========================================================================

    class << self

      # Executes the query object.
      #
      # @param user [User] User whose portfolios will be queried.
      # @return [ActiveRecord::Relation<Portfolio>] Aggregated portfolio relation.
      def call(user)
        new(user: user).call
      end
    end

    # ==========================================================================
    # INITIALIZATION
    # ==========================================================================

    # Initializes the query object.
    #
    # @param user [User] User whose portfolios will be queried.
    def initialize(user:)
      @user = user
    end

    # ==========================================================================
    # PUBLIC METHODS
    # ==========================================================================

    # Returns aggregated portfolio investment metrics for the user.
    #
    # The resulting relation includes:
    # - investment count
    # - total invested value
    # - total allocation percentage
    #
    # Portfolios without investments are preserved through LEFT JOIN semantics.
    #
    # @return [ActiveRecord::Relation<Portfolio>] Aggregated portfolio relation
    #   with computed investment metrics.
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

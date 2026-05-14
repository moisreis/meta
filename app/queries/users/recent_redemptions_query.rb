# Provides user-related query objects and data access operations.
#
# This namespace groups query services responsible for encapsulating
# user-specific database querying and reporting logic.
#
# @author Moisés Reis

module Users

  # Retrieves the most recent redemption requests associated with a user.
  #
  # This query object loads recent redemption records through portfolio-linked
  # fund investments while eager loading related associations to prevent
  # N+1 query behavior in dashboards and reporting interfaces.
  class RecentRedemptionsQuery

    # ==========================================================================
    # DEFAULT CONFIGURATION
    # ==========================================================================

    # Default number of recent redemptions returned by the query.
    #
    # @return [Integer] Default query result limit.
    DEFAULT_LIMIT = 5

    # ==========================================================================
    # PUBLIC CLASS METHODS
    # ==========================================================================

    class << self

      # Executes the query object.
      #
      # @param user [User] User whose recent redemptions will be queried.
      # @param limit [Integer] Maximum number of records to return.
      # @return [ActiveRecord::Relation<Redemption>] Ordered recent redemption
      #   records with eager-loaded associations.
      def call(user, limit: DEFAULT_LIMIT)
        new(user: user, limit: limit).call
      end
    end

    # ==========================================================================
    # INITIALIZATION
    # ==========================================================================

    # Initializes the query object.
    #
    # @param user [User] User whose recent redemptions will be queried.
    # @param limit [Integer] Maximum number of records to return.
    def initialize(user:, limit:)
      @user  = user
      @limit = limit
    end

    # ==========================================================================
    # PUBLIC METHODS
    # ==========================================================================

    # Returns the most recent redemptions associated with the user.
    #
    # The query:
    # - filters redemptions through portfolio ownership
    # - eager loads investment relationships
    # - orders results by request date descending
    # - limits the number of returned records
    #
    # @return [ActiveRecord::Relation<Redemption>] Ordered recent redemption
    #   records with eager-loaded associations.
    def call
      Redemption
        .joins(fund_investment: :portfolio)
        .where(portfolios: { user_id: @user.id })
        .includes(fund_investment: %i[portfolio investment_fund])
        .order(request_date: :desc)
        .limit(@limit)
    end
  end
end

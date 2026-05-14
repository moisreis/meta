# Provides user index querying and pagination behavior.
#
# This query object encapsulates search filtering, eager loading,
# authorization scoping, and pagination logic for user index listings.
#
# @author Moisés Reis

module Users

  # Executes searchable and paginated user index queries.
  #
  # This class isolates query composition and authorization-aware scope
  # selection from controllers to improve maintainability and testability.
  class IndexQuery

    # ==========================================================================
    # CONSTANTS
    # ==========================================================================

    # Number of records displayed per paginated page.
    #
    # @return [Integer] Pagination size for index results.
    PER_PAGE = AppConstants::INDEX_PER_PAGE

    # Immutable query result object returned by {.call}.
    #
    # @!attribute [r] search
    #   @return [Ransack::Search] Configured Ransack search object.
    #
    # @!attribute [r] records
    #   @return [ActiveRecord::Relation<User>] Paginated user records.
    Result = Struct.new(
      :search,
      :records,
      keyword_init: true
    )

    # ==========================================================================
    # PUBLIC CLASS METHODS
    # ==========================================================================

    class << self

      # Executes the query object.
      #
      # @param q_params [Hash] Ransack query parameters.
      # @param page [Integer, String] Current pagination page number.
      # @param actor [User] User executing the query.
      # @return [Result] Structured query result containing search and records.
      def call(q_params, page:, actor:)
        new(q_params, page: page, actor: actor).call
      end
    end

    # ==========================================================================
    # INITIALIZATION
    # ==========================================================================

    # Initializes the query object.
    #
    # @param q_params [Hash] Ransack query parameters.
    # @param page [Integer, String] Current pagination page number.
    # @param actor [User] User executing the query.
    def initialize(q_params, page:, actor:)
      @q_params = q_params
      @page     = page
      @actor    = actor
    end

    # ==========================================================================
    # PUBLIC METHODS
    # ==========================================================================

    # Executes the search and pagination workflow.
    #
    # @return [Result] Structured query result containing search and records.
    def call
      search = base_scope.ransack(@q_params)

      records = search
                .result(distinct: true)
                .includes(:portfolios)
                .page(@page)
                .per(PER_PAGE)

      Result.new(
        search: search,
        records: records
      )
    end

    private

    # ==========================================================================
    # PRIVATE METHODS
    # ==========================================================================

    # Returns the base scope available to the current actor.
    #
    # Administrators may access all users, while non-admin users
    # receive an empty relation.
    #
    # @return [ActiveRecord::Relation<User>] Authorization-scoped base relation.
    def base_scope
      @actor.admin? ? User.all : User.none
    end
  end
end

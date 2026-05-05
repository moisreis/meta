# frozen_string_literal: true

# app/queries/users/index_query.rb
#
# Encapsulates the filtering, searching, eager loading,
# and pagination logic used by UsersController#index.
#
# Administrators can search and paginate all users,
# while non-admin users receive an empty relation.
#
# @example
#   result = Users::IndexQuery.call(
#     params[:q],
#     page: params[:page],
#     actor: current_user
#   )
#
#   @q     = result.search
#   @users = result.records
#
# @author Moisés Reis
module Users
  class IndexQuery

    # ===========================================================
    #                        1. CONSTANTS
    # ===========================================================

    # Default number of records displayed per page.
    PER_PAGE = 14

    # ===========================================================
    #                     2. RESULT STRUCTURE
    # ===========================================================

    # Standardized query response object.
    #
    # @!attribute [r] search
    #   @return [Ransack::Search]
    #
    # @!attribute [r] records
    #   @return [ActiveRecord::Relation<User>]
    Result = Struct.new(
      :search,
      :records,
      keyword_init: true
    )

    # ===========================================================
    #                         3. ENTRYPOINT
    # ===========================================================

    # Executes the query workflow.
    #
    # @param q_params [ActionController::Parameters, Hash, nil]
    #   Ransack search parameters.
    #
    # @param page [Integer, String, nil]
    #   Current pagination page.
    #
    # @param actor [User]
    #   The authenticated user performing the query.
    #
    # @return [Result]
    def self.call(q_params, page:, actor:)
      new(q_params, page: page, actor: actor).call
    end

    # ===========================================================
    #                      4. INITIALIZATION
    # ===========================================================

    # Initializes query state.
    #
    # @param q_params [ActionController::Parameters, Hash, nil]
    # @param page [Integer, String, nil]
    # @param actor [User]
    #
    # @return [void]
    def initialize(q_params, page:, actor:)
      @q_params = q_params
      @page     = page
      @actor    = actor
    end

    # ===========================================================
    #                       5. QUERY WORKFLOW
    # ===========================================================

    # Applies authorization scoping, filtering,
    # eager loading, and pagination.
    #
    # @return [Result]
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

    # ===========================================================
    #                         6. BASE SCOPE
    # ===========================================================

    # Defines the base relation available to the actor.
    #
    # Administrators can access all users.
    # Non-admin users receive an empty relation.
    #
    # @return [ActiveRecord::Relation<User>]
    def base_scope
      @actor.admin? ? User.all : User.none
    end
  end
end
# frozen_string_literal: true

# app/queries/portfolios/index_query.rb
#
# Encapsulates filtering, authorization scoping,
# eager loading, sorting, and pagination logic
# used by PortfoliosController#index.
#
# Administrators can access all portfolios.
# Regular users can only access authorized portfolios.
#
# @example
#   result = Portfolios::IndexQuery.call(
#     params[:q],
#     page: params[:page],
#     sort: params[:sort],
#     direction: params[:direction],
#     actor: current_user
#   )
#
#   @q            = result.search
#   @portfolios   = result.records
#   @total_items  = result.total_items
#
# @author Moisés Reis
module Portfolios
  class IndexQuery

    # ===========================================================
    #                         1. CONSTANTS
    # ===========================================================

    PER_PAGE = 14

    ALLOWED_SORT_COLUMNS = %w[
      id
      name
      created_at
      updated_at
    ].freeze

    ALLOWED_DIRECTIONS = %w[
      asc
      desc
    ].freeze

    # ===========================================================
    #                     2. RESULT STRUCTURE
    # ===========================================================

    Result = Struct.new(
      :search,
      :records,
      :total_items,
      keyword_init: true
    )

    # ===========================================================
    #                        3. ENTRYPOINT
    # ===========================================================

    # @param q_params [ActionController::Parameters, Hash, nil]
    # @param page [Integer, String, nil]
    # @param sort [String, nil]
    # @param direction [String, nil]
    # @param actor [User]
    #
    # @return [Result]
    def self.call(
      q_params,
      page:,
      sort:,
      direction:,
      actor:
    )
      new(
        q_params,
        page: page,
        sort: sort,
        direction: direction,
        actor: actor
      ).call
    end

    # ===========================================================
    #                     4. INITIALIZATION
    # ===========================================================

    # @param q_params [ActionController::Parameters, Hash, nil]
    # @param page [Integer, String, nil]
    # @param sort [String, nil]
    # @param direction [String, nil]
    # @param actor [User]
    #
    # @return [void]
    def initialize(
      q_params,
      page:,
      sort:,
      direction:,
      actor:
    )
      @q_params = q_params
      @page = page
      @sort = sort
      @direction = direction
      @actor = actor
    end

    # ===========================================================
    #                      5. QUERY WORKFLOW
    # ===========================================================

    # @return [Result]
    def call
      search = base_scope
                 .preload(:user)
                 .ransack(@q_params)

      filtered = search.result(distinct: true)

      records = filtered
                  .order(order_clause)
                  .page(@page)
                  .per(PER_PAGE)

      Result.new(
        search: search,
        records: records,
        total_items: filtered.count
      )
    end

    private

    # ===========================================================
    #                        6. BASE SCOPE
    # ===========================================================

    # @return [ActiveRecord::Relation<Portfolio>]
    def base_scope
      @actor.admin? ? Portfolio.all : Portfolio.for_user(@actor)
    end

    # ===========================================================
    #                       7. ORDERING
    # ===========================================================

    # @return [String]
    def order_clause
      "portfolios.#{safe_sort} #{safe_direction}"
    end

    # @return [String]
    def safe_sort
      ALLOWED_SORT_COLUMNS.include?(@sort) ? @sort : "id"
    end

    # @return [String]
    def safe_direction
      ALLOWED_DIRECTIONS.include?(@direction) ? @direction : "asc"
    end
  end
end
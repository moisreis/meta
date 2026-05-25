# frozen_string_literal: true

module FundInvestments

  # Encapsulates filtering, authorization scoping, eager loading,
  # sorting, and pagination logic used by
  # {FundInvestmentsController#index}.
  #
  # Administrators can access all fund investments.
  # Regular users can only access authorized investments.
  #
  # @example
  #   result = FundInvestments::IndexQuery.call(
  #     params[:q],
  #     page: params[:page],
  #     sort: params[:sort],
  #     direction: params[:direction],
  #     actor: current_user
  #   )
  #
  #   @q                = result.search
  #   @fund_investments = result.records
  #   @total_items      = result.total_items
  #
  # @author Moisés Reis  
  class IndexQuery

    # =============================================================
    #                         CONSTANTS
    # =============================================================

    PER_PAGE = 14

    ALLOWED_SORT_COLUMNS = %w[
      id
      total_invested_value
      total_quotas_held
      percentage_allocation
      created_at
      updated_at
    ].freeze

    ALLOWED_DIRECTIONS = %w[
      asc
      desc
    ].freeze

    # =============================================================
    #                      RESULT STRUCTURE
    # =============================================================

    Result = Struct.new(
      :search,
      :records,
      :total_items,
      keyword_init: true
    )

    # =============================================================
    #                         ENTRYPOINT
    # =============================================================

    # Dispatches a paginated, filtered, and sorted query.
    #
    # @param q_params [ActionController::Parameters, Hash, nil]
    #   Ransack search parameters.
    # @param page [Integer, String, nil] Page number for pagination.
    # @param sort [String, nil] Column name to sort by.
    # @param direction [String, nil] Sort direction ("asc" or "desc").
    # @param actor [User] The currently authenticated user.
    #
    # @return [Result] Struct containing search, records, and total_items.
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

    # =============================================================
    #                       INITIALIZATION
    # =============================================================

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

    # =============================================================
    #                       QUERY WORKFLOW
    # =============================================================

    # Executes the full query pipeline.
    #
    # Applies authorization scoping, Ransack filtering, sorting,
    # and Kaminari pagination in sequence.
    #
    # @return [Result]
    def call
      search = base_scope
                 .includes(
                   :investment_fund,
                   :portfolio
                 )
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

    # =============================================================
    #                        BASE SCOPE
    # =============================================================

    # Returns the authorized scope of fund investments.
    #
    # Administrators see all records; regular users see only
    # those accessible through {FundInvestment.accessible_to}.
    #
    # @return [ActiveRecord::Relation<FundInvestment>]
    def base_scope
      @actor.admin? ? FundInvestment.all : FundInvestment.accessible_to(@actor)
    end

    # =============================================================
    #                         ORDERING
    # =============================================================

    # Builds a safe SQL ordering clause.
    #
    # @return [String] e.g. "fund_investments.id asc"
    def order_clause
      "fund_investments.#{safe_sort} #{safe_direction}"
    end

    # Returns the sort column after allow-list validation.
    #
    # @return [String]
    def safe_sort
      ALLOWED_SORT_COLUMNS.include?(@sort) ? @sort : "id"
    end

    # Returns the sort direction after allow-list validation.
    #
    # @return [String]
    def safe_direction
      ALLOWED_DIRECTIONS.include?(@direction) ? @direction : "asc"
    end
  end
end

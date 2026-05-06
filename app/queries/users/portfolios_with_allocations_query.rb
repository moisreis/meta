# frozen_string_literal: true

# app/queries/users/portfolios_with_allocations_query.rb
#
# Loads all portfolios belonging to a specific user together with
# their associated fund investments.
#
# This query exists to support allocation validation workflows
# without triggering N+1 queries when calling methods such as
# `valid_allocations?` across multiple portfolios.
#
# @example
#   portfolios = Users::PortfoliosWithAllocationsQuery.call(user)
#
#   portfolios.each do |portfolio|
#     portfolio.valid_allocations?
#   end
#
# @author Moisés Reis
module Users
  class PortfoliosWithAllocationsQuery

    # ===========================================================
    #                         1. ENTRYPOINT
    # ===========================================================

    # Executes the query.
    #
    # @param user [User]
    # @return [ActiveRecord::Relation<Portfolio>]
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

    # Returns all portfolios for the provided user with
    # fund investments eager loaded.
    #
    # @return [ActiveRecord::Relation<Portfolio>]
    def call
      Portfolio
        .where(user_id: @user.id)
        .includes(:fund_investments)
    end
  end
end
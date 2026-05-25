# frozen_string_literal: true

# Retrieves portfolios and associated investment allocations for a user.
#
# This query object loads user portfolios together with their associated
# fund investments to avoid N+1 queries during allocation rendering and
# reporting workflows.
#
# @author Moisés Reis

module Users
  class PortfoliosWithAllocationsQuery

    # =============================================================
    #                     PUBLIC CLASS METHODS
    # =============================================================

    class << self

      # Executes the query object.
      #
      # @param user [User] User whose portfolios will be queried.
      # @return [ActiveRecord::Relation<Portfolio>] Portfolios with eager-loaded
      #   fund investments.
      def call(user)
        new(user).call
      end
    end

    # =============================================================
    #                        INITIALIZATION
    # =============================================================

    # Initializes the query object.
    #
    # @param user [User] User whose portfolios will be queried.
    def initialize(user)
      @user = user
    end

    # =============================================================
    #                        PUBLIC METHODS
    # =============================================================

    # Returns portfolios with preloaded fund investment allocations.
    #
    # Eager loading is used to prevent N+1 query behavior when accessing
    # associated fund investments.
    #
    # @return [ActiveRecord::Relation<Portfolio>] Portfolios with eager-loaded
    #   fund investments.
    def call
      Portfolio
        .where(user_id: @user.id)
        .includes(:fund_investments)
    end
  end
end

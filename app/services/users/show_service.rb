# frozen_string_literal: true

# app/services/users/show_service.rb
#
# Aggregates all data required to render the user show page.
# Each query is delegated to a dedicated query object.
#
# Consolidations applied vs previous version:
#   - portfolios_count is derived from the portfolios relation — no separate COUNT query.
#   - total_invested is derived from portfolios aggregate — no separate SUM query.
#   - portfolios_for_compliance is kept separate as it serves a different purpose.
#   - User is never re-fetched; it is passed in from the controller.
#
# @author Moisés Reis
module Users
  class ShowService

    # =============================================================
    #                          1. RESULT
    # =============================================================

    Result = Struct.new(
      :user,
      :portfolios,
      :portfolios_count,
      :total_invested,
      :total_balance,
      :portfolios_for_compliance,
      :recent_applications,
      :recent_redemptions,
      :last_sign_in_at,
      :created_at,
      :sign_in_count,
      keyword_init: true
    )

    private_class_method :new

    # =============================================================
    #                      2. PUBLIC INTERFACE
    # =============================================================

    # @param user [User]
    # @return [Result]
    def self.call(user)
      new(user).send(:call)
    end

    # =============================================================
    #                       3. INITIALIZATION
    # =============================================================

    def initialize(user)
      @user = user
    end

    # =============================================================
    #                        4. EXECUTION
    # =============================================================

    def call

      # Load portfolios once with all aggregates pre-computed.
      # total_invested_value and fund_investments_count are selected
      # as SQL aggregates — no per-portfolio queries needed in the view.
      portfolios = Users::PortfoliosQuery.call(@user)

      # Derive count and total from the already-loaded relation
      # to avoid two extra round-trips (Users::PortfoliosCountQuery
      # and Users::TotalInvestedQuery are no longer called separately).
      portfolios_count = portfolios.length
      total_invested   = portfolios.sum(&:total_invested_value)

      Result.new(
        user:                      @user,
        portfolios:                portfolios,
        portfolios_count:          portfolios_count,
        total_invested:            total_invested,
        total_balance:             Users::TotalBalanceQuery.call(@user),
        portfolios_for_compliance: Users::PortfoliosWithAllocationsQuery.call(@user),
        recent_applications:       Users::RecentApplicationsQuery.call(@user),
        recent_redemptions:        Users::RecentRedemptionsQuery.call(@user),
        last_sign_in_at:           @user.last_sign_in_at,
        created_at:                @user.created_at,
        sign_in_count:             @user.sign_in_count
      )
    end
  end
end
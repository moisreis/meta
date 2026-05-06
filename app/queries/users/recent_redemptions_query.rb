# frozen_string_literal: true

# app/queries/users/recent_redemptions_query.rb
#
# Returns the most recent redemption requests associated with
# portfolios owned by a specific user.
#
# This query eager loads all required associations to avoid N+1
# queries when rendering redemption activity views.
#
# @example
#   redemptions = Users::RecentRedemptionsQuery.call(user)
#
#   redemptions.each do |redemption|
#     redemption.fund_investment.portfolio.name
#     redemption.fund_investment.investment_fund.fund_name
#   end]
#
# @author Moisés Reis
module Users
  class RecentRedemptionsQuery
    DEFAULT_LIMIT = 5

    # ===========================================================
    #                         1. ENTRYPOINT
    # ===========================================================

    # Executes the query.
    #
    # @param user [User]
    # @param limit [Integer]
    # @return [ActiveRecord::Relation<Redemption>]
    def self.call(user, limit: DEFAULT_LIMIT)
      new(user, limit).call
    end

    private

    # ===========================================================
    #                        2. INITIALIZATION
    # ===========================================================

    # @param user [User]
    # @param limit [Integer]
    def initialize(user, limit)
      @user  = user
      @limit = limit
    end

    public

    # ===========================================================
    #                           3. QUERY
    # ===========================================================

    # Returns the latest redemption records associated with
    # the user's portfolios.
    #
    # @return [ActiveRecord::Relation<Redemption>]
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
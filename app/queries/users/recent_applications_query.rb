# app/queries/users/recent_applications_query.rb
#
# Returns the most recent applications for a given user.
#
# This query object encapsulates the retrieval of application records
# associated with a user's portfolios. It isolates database querying logic
# from controllers and views to improve maintainability and testability.
#
# @author Moisés Reis
module Users
  class RecentApplicationsQuery

  # =============================================================
  #                      1. PUBLIC INTERFACE
  # =============================================================

  # Executes the query using a class-level interface.
  #
  # @param user [User] The user whose applications should be retrieved.
  # @param limit [Integer] Maximum number of records to return (default: 5).
  # @return [ActiveRecord::Relation<Application>] The filtered application records.
  def self.call(user, limit: 5)
    new(user, limit).call
  end

  # =============================================================
  #                        2. INITIALIZATION
  # =============================================================

  # Initializes the query object.
  #
  # @param user [User] The target user.
  # @param limit [Integer] Maximum number of records to return.
  # @return [void]
  def initialize(user, limit)
    @user  = user
    @limit = limit
  end

  public

  # =============================================================
  #                      3. QUERY EXECUTION
  # =============================================================

  # Executes the database query.
  #
  # @return [ActiveRecord::Relation<Application>] The resulting applications.
  def call
    Application
      .joins(fund_investment: :portfolio)
      .where(portfolios: { user_id: @user.id })
      .includes(fund_investment: [:portfolio, :investment_fund])
      .order(request_date: :desc)
      .limit(@limit)
  end
  end
end
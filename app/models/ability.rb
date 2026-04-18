# Defines the authorization rules for every user in the application. [cite: 35]
#
# This class acts as the application's security guard, defining the exact access
# level for every user based on roles and relationships using the CanCan library. [cite: 36, 182]
#
# @author Moisés Reis [cite: 37, 46]
class Ability
  include CanCan::Ability

  # Initializes user permissions and sets up administrative overrides. [cite: 60]
  #
  # @param user [User] The currently logged-in User object.
  # @return [void] [cite: 58, 69]
  def initialize(user)
    return unless user

    # Grant total access if the user has an administrative role.
    return can :manage, :all if user.admin?

    define_portfolio_abilities(user)
    define_special_abilities(user)
  end

  private

  # Establishes reading and management permissions based on the user's
  # relationship to a specific portfolio.
  #
  # @param user [User] [cite: 58]
  def define_portfolio_abilities(user)
    resources = [
      Portfolio,
      FundInvestment,
      Application,
      Redemption
    ]

    resources.each do |resource|
      # Grant read access if the parent portfolio is readable by the user.
      can :read, resource, portfolio: Portfolio.readable_by(user).select(:id)

      # Grant management access if the parent portfolio is manageable by the user.
      can :manage, resource, portfolio: Portfolio.manageable_by(user).select(:id)
    end
  end

  # Defines individual, non-portfolio-dependent permissions for a user.
  #
  # @param user [User] [cite: 58]
  def define_special_abilities(user)
    # Manage reports logs that belong directly to the user.
    can :manage, ReportsLog, user_id: user.id

    # Allow users to read their own profile details.
    can :read, User, id: user.id

    # Read investment funds based on visibility scopes.
    can :read, InvestmentFund, id: InvestmentFund.readable_by(user).select(:id)
  end
end

# === ability
#
# @author Moisés Reis
# @added 11/25/2025
# @package *Meta*
# @description This class defines the authorization rules for every user,
#              determining what actions (like reading, creating, or managing)
#              they are permitted to perform on specific data models (resources) in the application.
#              The explanations are in the present simple tense.
# @category *Model*
#
# Usage:: - *[What]* This code block acts as the application's security guard,
#           defining the exact access level for every user who logs in.
#         - *[How]* It uses the **CanCan** library to check the user's roles and relationships,
#           then sets permissions (e.g., `can :read, Portfolio`) based on those checks.
#         - *[Why]* It ensures that users can only see and modify the data they are supposed to,
#           preventing unauthorized access and maintaining the security of sensitive information.
#
# Attributes:: - *user* @object - The currently logged-in **User** object whose permissions are being defined.
#
class Ability

  # Explanation:: This includes the core functionality from the **CanCan::Ability**
  #               module, which provides the methods like `can` and `cannot` used to define permissions.
  include CanCan::Ability

  # == initialize
  #
  # @author Moisés Reis
  # @category *Logic*
  #
  # Logic:: This method runs immediately when a user logs in or attempts an action, setting up all their specific permissions.
  #         It starts by checking for administrator status before assigning regular user abilities.
  #
  # Attributes:: - *@user* - The currently logged-in **User** object.
  #
  def initialize(user)

    # Explanation:: This immediately stops the initialization process if there is no user
    #               logged in (guest user), preventing potential errors.
    return unless user

    # Explanation:: This grants the user permission to perform any action (`:manage`) on all
    #               resources (`:all`) if the user has the administrative role (`user.admin?`).
    return can :manage, :all if user.admin?

    # Explanation:: This calls a separate, private method to define permissions related to
    #               portfolios and resources linked to those portfolios.
    define_portfolio_abilities(user)

    # Explanation:: This calls another separate, private method to define unique,
    #               non-portfolio-based permissions, such as access to their own user profile or reports.
    define_special_abilities(user)
  end

  private

  # == define_portfolio_abilities
  #
  # @author Moisés Reis
  # @category *Permissions*
  #
  # Permissions:: This method establishes reading and management permissions based on the user's relationship to a specific portfolio.
  #               If a user manages a portfolio, they can manage all its related records; if they can only read it, they can only read the related records.
  #
  # Attributes:: - *@user* - The **User** object whose permissions are being set.
  #
  def define_portfolio_abilities(user)

    # Explanation:: This defines an array of all data models (resources) that are directly
    #               linked to a portfolio and whose permissions must be checked against it.
    resources = [
      Portfolio,
      FundInvestment,
      Application,
      Redemption
    ]

    # Explanation:: This starts a loop to apply the same set of portfolio-based rules
    #               to every resource listed in the array above.
    resources.each do |resource|

      # Explanation:: This grants permission to read the resource only if the resource's
      #               parent portfolio is one that the user has been granted read access to.
      can :read, resource, portfolio: Portfolio.readable_by(user).select(:id)

      # Explanation:: This grants permission to manage (create, update, delete) the resource
      #               only if the resource's parent portfolio is one that the user has management access to.
      can :manage, resource, portfolio: Portfolio.manageable_by(user).select(:id)
    end
  end

  # == define_special_abilities
  #
  # @author Moisés Reis
  # @category *Permissions*
  #
  # Permissions:: This method defines individual, non-portfolio-dependent permissions for a user, such as access to their own data or specific system logs.
  #               It grants the user the ability to interact with certain models directly.
  #
  # Attributes:: - *@user* - The **User** object whose permissions are being set.
  #
  def define_special_abilities(user)

    # Explanation:: This allows a user to fully manage (read, create, update, delete) a
    #               ReportsLog record only if that log belongs directly to their user ID.
    can :manage, ReportsLog, user_id: user.id

    # Explanation:: This allows a user to read their own **User** record (e.g., to view
    #               their own profile details) but restricts access to other user profiles.
    can :read, User, id: user.id

    # Explanation:: This allows a user to read **InvestmentFund** records only if those
    #               funds are marked as globally readable or specifically linked to the user.
    can :read, InvestmentFund, id: InvestmentFund.readable_by(user).select(:id)
  end
end
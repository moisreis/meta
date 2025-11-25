# === user_portfolio_permissions_helper
#
# @author Moisés Reis
# @added 11/25/2025
# @package *Meta*
# @description This file contains utility methods used to determine and display a **User**'s access and permission levels
#              for specific **Portfolio** resources throughout the application.
#              The explanations are in the present simple tense.
# @category *Helper*
#
# Usage:: - *[What]* This code block provides small, focused functions that check what a user is allowed to do within a given portfolio.
#         - *[How]* It defines methods that take a user object and a portfolio object, consults the database permissions,
#           and returns a boolean value (true/false) or a readable string representing the user's role.
#         - *[Why]* It centralizes complex permission logic, making it easy for **Views** to decide whether to show or hide actions
#           (like editing or deleting) based on the current user's security level.
#
module UserPortfolioPermissionsHelper
end
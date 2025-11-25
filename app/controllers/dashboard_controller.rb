# === dashboard_controller
#
# @author Moisés Reis
# @added 11/24/2025
# @package *Meta*
# @description This controller manages the main personalized overview page (dashboard)
#              for the currently authenticated user. It serves as the primary landing
#              page after login and displays summary data from modules like **FundInvestment**
#              and **Application**.
# @category *Controller*
#
# Usage:: - *[What]* This code block controls the initial page a user sees, which
#           summarizes their activity and key metrics.
#         - *[How]* It typically fetches aggregated data from several models (though
#           the current version only renders) before instructing the system to display the page.
#         - *[Why]* It provides the user with immediate context and quick access to
#           the most important application features.
#
# Attributes:: - @controller_variable - This minimal version does not set instance variables.
#
class DashboardController < ApplicationController

  # Explanation:: This runs before any action and ensures the current user is
  #               successfully logged into the system before they can access the dashboard.
  before_action :authenticate_user!

  # == index
  #
  # @author Moisés Reis
  # @category *Read*
  #
  # Read:: This action serves as the main entry point for the dashboard.
  #        It simply instructs the system to load and display the associated
  #        index view template to the user.
  #
  def index
    render
  end
end
# === dashboard_controller
#
# @author Moisés Reis
# @added 11/13/2025
# @package *Meta*
# @description Defines the controller that manages the dashboard interface.
#              Keeps the dashboard logic isolated and organized inside **DashboardController**,
#              which inherits behavior and configuration from **ApplicationController**.
# @category *Controller*
#
# Usage:: - *[what]* This controller handles requests related to the dashboard.
#         - *[how]* It renders the dashboard view through the *index* action
#                   using the default rendering pipeline from **ActionController::Base**.
#         - *[why]* It separates dashboard presentation logic from other controllers,
#                   ensuring clear routing, maintenance, and access structure.
#
# Attributes:: - None
#
class DashboardController < ApplicationController

  # [Action] Renders the dashboard *index* view.
  #          Uses the default rendering pipeline and returns the associated template.
  def index
    render
  end
end
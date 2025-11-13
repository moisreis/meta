# === dashboard_controller
#
# @author Moisés Reis
# @added 11/13/2025
# @package *Meta*
# @description Handles the logic for displaying the user dashboard.
#              Retrieves the necessary data and renders the main dashboard view.
#              Inherits from **ApplicationController** to maintain shared app-wide behavior and filters.
# @category *Controller*
#
# Usage:: - *[what]* Renders the dashboard page for authenticated users.
#         - *[how]* Calls the **index** action to render the associated view without additional processing.
#         - *[why]* Provides a centralized entry point for the user's workspace or control panel.
#
class DashboardController < ApplicationController

  def index
    render
  end
end

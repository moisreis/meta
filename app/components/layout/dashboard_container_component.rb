# frozen_string_literal: true

# Component responsible for rendering the main dashboard layout container.
#
# This component centralizes page title, optional description, and view state
# management for dashboard screens.
#
# @author Moisés Reis

class Layout::DashboardContainerComponent < ApplicationComponent

  # ==========================================================================
  # INITIALIZATION
  # ==========================================================================

  # @param page_title [String] The main heading for the dashboard page.
  # @param page_desc [String, nil] Optional subtitle or explanatory text.
  # @param current_view [String] Determines specific styling or logic based on the view type (default: "form").
  def initialize(page_title:, page_desc: nil, current_view: "form")
    @page_title   = page_title
    @page_desc    = page_desc
    @current_view = current_view
  end
end

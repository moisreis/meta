# frozen_string_literal: true

# Component responsible for wrapping dashboard layouts and enforcing view state
# constraints (form, show, index).
#
# This component validates the current view mode and provides a consistent
# container abstraction for dashboard pages.
#
# @author Moisés Reis
class Layout::DashboardWrapperComponent < ApplicationComponent

  # ==========================================================================
  # CONSTANTS
  # ==========================================================================

  # Allowed view modes to ensure consistent layout behavior.
  VALID_VIEWS = %w[form show index].freeze

  # ==========================================================================
  # INITIALIZATION
  # ==========================================================================

  # @param page_title [String] The title displayed in the dashboard header.
  # @param page_desc [String, nil] Optional description or subtitle.
  # @param current_view [String] The layout mode; defaults to "form" if invalid.
  def initialize(page_title:, page_desc: nil, current_view: "form")
    @page_title   = page_title
    @page_desc    = page_desc
    @current_view = VALID_VIEWS.include?(current_view) ? current_view : "form"
  end
end

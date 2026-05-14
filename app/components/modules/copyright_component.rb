# frozen_string_literal: true

# Component responsible for rendering application copyright information.
#
# This component exposes the current year for UI display in footer or layout
# elements where dynamic date rendering is required.
#
# @author Moisés Reis

class Modules::CopyrightComponent < ApplicationComponent

  # ==========================================================================
  # INITIALIZATION
  # ==========================================================================

  def initialize
    super
  end

  # ==========================================================================
  # PUBLIC METHODS
  # ==========================================================================

  # Returns the current year based on the application's configured time zone.
  #
  # @return [Integer] The current year (e.g., 2026).
  def current_year
    Time.current.year
  end
end

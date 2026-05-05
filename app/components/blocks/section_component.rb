# Provides a reusable layout container for dashboard sections with
# configurable grid columns, optional title, description, and actions.
#
# This component standardizes section layout composition across the
# application, ensuring consistent spacing, responsiveness, and structure
# for grouped UI blocks such as cards, tables, and activity panels.
#
# TABLE OF CONTENTS:
#   1.  Configuration
#   2.  Initialization
#   3.  Public Interface
#       3a. Grid Classes
#       3b. Presence Helpers
#       3c. DOM Utilities
#
# @author Moisés Reis
class Blocks::SectionComponent < ApplicationComponent

  # =============================================================
  #                        1. CONFIGURATION
  # =============================================================

  GRID_CLASSES = {
    1 => "grid-cols-1",
    2 => "grid-cols-1 md:grid-cols-2",
    3 => "grid-cols-1 md:grid-cols-2 lg:grid-cols-3",
    4 => "grid-cols-1 md:grid-cols-2 lg:grid-cols-3 3xl:grid-cols-4",
    5 => "grid-cols-1 md:grid-cols-2 lg:grid-cols-3 3xl:grid-cols-4",
    6 => "grid-cols-1 md:grid-cols-2 lg:grid-cols-3 3xl:grid-cols-4"
  }.freeze

  FALLBACK_GRID_CLASS = "grid-cols-1 sm:grid-cols-2 lg:grid-cols-3"

  # =============================================================
  #                        2. INITIALIZATION
  # =============================================================

  # Initializes a SectionComponent.
  #
  # @param title [String, nil] Section title displayed in header.
  # @param description [String, nil] Optional section description text.
  # @param columns [Integer] Number of grid columns (default: 2).
  # @param action [Hash, nil] Optional action configuration for header button.
  # @return [void]
  def initialize(title: nil, description: nil, columns: 2, action: nil)
    @title       = title
    @description = description
    @columns     = columns
    @action      = action
  end

  # =============================================================
  #                      3. PUBLIC INTERFACE
  # =============================================================

  # =============================================================
  #                     3a. GRID CLASSES
  # =============================================================

  # Returns the CSS grid class string based on column configuration.
  #
  # @return [String] Tailwind grid class definition.
  def grid_classes
    GRID_CLASSES.fetch(@columns, FALLBACK_GRID_CLASS)
  end

  # =============================================================
  #                     3b. PRESENCE HELPERS
  # =============================================================

  # Indicates whether a title is present.
  #
  # @return [Boolean]
  def title?
    @title.present?
  end

  # Indicates whether a description is present.
  #
  # @return [Boolean]
  def description?
    @description.present?
  end

  # Indicates whether an action is present.
  #
  # @return [Boolean]
  def action?
    @action.present?
  end

  # =============================================================
  #                     3c. DOM UTILITIES
  # =============================================================

  # Generates a DOM-safe identifier for the description element.
  #
  # @return [String] Parameterized DOM id derived from title.
  def description_dom_id
    "#{@title.parameterize}-desc"
  end
end
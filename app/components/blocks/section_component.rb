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
#       3b. Separator Classes
#       3c. Presence Helpers
#       3d. DOM Utilities
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

  # Accepted separator orientations.
  VALID_SEPARATORS = %i[vertical horizontal both].freeze

  # =============================================================
  #                        2. INITIALIZATION
  # =============================================================

  # Initializes a SectionComponent.
  #
  # @param title [String, nil] Section title displayed in header.
  # @param description [String, nil] Optional section description text.
  # @param columns [Integer] Number of grid columns (default: 2).
  # @param action [Hash, nil] Optional action configuration for header button.
  # @param separator [Symbol, nil] Optional inter-item separator.
  #   Accepts :vertical (between columns), :horizontal (between rows),
  #   :both, or nil (no separator). Default: nil.
  # @return [void]
  def initialize(title: nil, description: nil, columns: 2, action: nil, separator: nil)
    @title       = title
    @description = description
    @columns     = columns
    @action      = action
    @separator   = separator.in?(VALID_SEPARATORS) ? separator : nil
  end

  # =============================================================
  #                      3. PUBLIC INTERFACE
  # =============================================================

  # =============================================================
  #                      3a. GRID CLASSES
  # =============================================================

  # Returns the CSS grid class string based on column configuration.
  #
  # @return [String] Tailwind grid class definition.
  def grid_classes
    GRID_CLASSES.fetch(@columns, FALLBACK_GRID_CLASS)
  end

  # Returns gap classes with the divided axis collapsed to zero.
  #
  # When a separator is active on an axis, its gap is removed so the divide
  # border lands exactly at the content boundary. Spacing on that axis is
  # then owned entirely by the padding injected onto children via [&>*].
  #
  # @return [String]
  def gap_classes
    case @separator
    when :vertical   then "gap-y-6"   # column gap removed — divider owns that axis
    when :horizontal then "gap-x-6"   # row gap removed    — divider owns that axis
    when :both       then ""          # both gaps removed
    else                  "gap-6"
    end
  end

  # =============================================================
  #                      3b. SEPARATOR CLASSES
  # =============================================================

  # Returns Tailwind divide + child-padding classes for the configured
  # separator orientation.
  #
  # divide-x / divide-y draw the line at the element boundary.
  # [&>*]:px-4 / [&>*]:py-4 inject symmetric padding on every direct grid
  # child without touching the child components themselves, ensuring the
  # line has balanced breathing room on both sides.
  #
  # Returns an empty string when no separator is configured, leaving
  # existing renders completely unaffected.
  #
  # @return [String]
  def separator_classes
    case @separator
    when :vertical   then "divide-x divide-border/70 [&>*]:px-4"
    when :horizontal then "divide-y divide-border/70 [&>*]:py-4"
    when :both       then "divide-x divide-y divide-border/70 [&>*]:px-4 [&>*]:py-4"
    else                  ""
    end
  end

  # =============================================================
  #                      3c. PRESENCE HELPERS
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
  #                      3d. DOM UTILITIES
  # =============================================================

  # Generates a DOM-safe identifier for the description element.
  #
  # @return [String] Parameterized DOM id derived from title.
  def description_dom_id
    "#{@title.parameterize}-desc"
  end
end
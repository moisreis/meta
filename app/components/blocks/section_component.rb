# frozen_string_literal: true

# Component responsible for rendering a structured content section with
# configurable grid layout, optional header metadata, and separator styling.
#
# This component is used as a layout primitive for grouping UI blocks
# consistently across dashboards and feature pages.
#
# @author Moisés Reis

class Blocks::SectionComponent < ApplicationComponent

  # ==========================================================================
  # CONSTANTS
  # ==========================================================================

  # Responsive grid mappings based on the number of columns requested.
  GRID_CLASSES = {
    1 => "grid-cols-1",
    2 => "grid-cols-1 md:grid-cols-2",
    3 => "grid-cols-1 md:grid-cols-2 lg:grid-cols-3",
    4 => "grid-cols-1 md:grid-cols-2 lg:grid-cols-3 3xl:grid-cols-4",
    5 => "grid-cols-1 md:grid-cols-2 lg:grid-cols-3 3xl:grid-cols-4",
    6 => "grid-cols-1 md:grid-cols-2 lg:grid-cols-3 3xl:grid-cols-4"
  }.freeze

  # Default grid behavior if columns input is out of mapped bounds.
  FALLBACK_GRID_CLASS = "grid-cols-1 sm:grid-cols-2 lg:grid-cols-3"

  # Permitted separator types for layout division.
  VALID_SEPARATORS = %i[vertical horizontal both].freeze

  # ==========================================================================
  # INITIALIZATION
  # ==========================================================================

  # @param title [String, nil] Section heading text.
  # @param description [String, nil] Explanatory text rendered below the title.
  # @param columns [Integer] Target column count for the grid (1-6).
  # @param action [Hash, nil] Optional link (e.g., { label: "View All", path: "/..." }).
  # @param separator [Symbol, nil] Type of visual division between grid items.
  def initialize(title: nil, description: nil, columns: 2, action: nil, separator: nil)
    @title       = title
    @description = description
    @columns     = columns
    @action      = action
    @separator   = separator.in?(VALID_SEPARATORS) ? separator : nil
  end

  # ==========================================================================
  # GRID CONFIGURATION
  # ==========================================================================

  # Returns Tailwind classes for the grid structure.
  # @return [String]
  def grid_classes
    GRID_CLASSES.fetch(@columns, FALLBACK_GRID_CLASS)
  end

  # Adjusts spacing based on whether separators are present.
  # @return [String]
  def gap_classes
    case @separator
    when :vertical   then "gap-y-6"
    when :horizontal then "gap-x-6"
    when :both       then ""
    else                  "gap-6"
    end
  end

  # Returns Tailwind 'divide' classes for internal borders.
  # @return [String]
  def separator_classes
    case @separator
    when :vertical   then "divide-x divide-border/70 [&>*]:px-4"
    when :horizontal then "divide-y divide-border/70 [&>*]:py-4"
    when :both       then "divide-x divide-y divide-border/70 [&>*]:px-4 [&>*]:py-4"
    else                  ""
    end
  end

  # ==========================================================================
  # QUERY METHODS
  # ==========================================================================

  # @return [Boolean]
  def title?
    @title.present?
  end

  # @return [Boolean]
  def description?
    @description.present?
  end

  # @return [Boolean]
  def action?
    @action.present?
  end

  # Generates a slug-based ID for accessibility relations.
  # @return [String]
  def description_dom_id
    "#{@title.parameterize}-desc" if title?
  end
end

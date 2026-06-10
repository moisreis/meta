# frozen_string_literal: true

# app/components/blocks/section_component.rb
#
# Component responsible for rendering a structured content section with
# configurable grid layout, optional header metadata, and separator styling.
#
# This component is used as a layout primitive for grouping UI blocks
# consistently across dashboards and feature pages.
#
# @author  Moisés Reis

class Blocks::SectionComponent < ApplicationComponent

  # == Constants ==============================================================

  # -- Layout Mappings --------------------------------------------------------

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


  # == Class Methods ==========================================================

  # Initializes the section component with structurally constrained layout properties.
  #
  # @param title [String, nil] Section heading text.
  # @param description [String, nil] Explanatory text rendered below the title.
  # @param columns [Integer] Target column count for the grid (1-6).
  # @param action [Hash, nil] Optional link (e.g., { label: "View All", path: "/..." }).
  # @param separator [Symbol, nil] Type of visual division between grid items.
  # @return [Blocks::SectionComponent]
  def initialize(title: nil, description: nil, columns: 2, action: nil, separator: nil)
    @title       = title
    @description = description
    @columns     = columns
    @action      = action
    @separator   = separator.in?(VALID_SEPARATORS) ? separator : nil
  end


  # == Instance Methods =======================================================

  # -- Grid Configuration -----------------------------------------------------

  # Returns Tailwind classes for the grid structure.
  #
  # @return [String] Tailwind layout utility classes.
  def grid_classes
    GRID_CLASSES.fetch(@columns, FALLBACK_GRID_CLASS)
  end

  # Adjusts spacing based on whether separators are present.
  #
  # @return [String] Tailwind gap utility classes.
  def gap_classes
    case @separator
    when :vertical   then "gap-y-6"
    when :horizontal then "gap-x-6"
    when :both       then ""
    else                  "gap-6"
    end
  end

  # Returns Tailwind 'divide' classes for internal borders.
  #
  # @return [String] Tailwind layout utility styles for pseudo-borders and matching child padding.
  def separator_classes
    case @separator
    when :vertical   then "divide-x divide-border/70 [&>*]:px-4"
    when :horizontal then "divide-y divide-border/70 [&>*]:py-4"
    when :both       then "divide-x divide-y divide-border/70 [&>*]:px-4 [&>*]:py-4"
    else                  ""
    end
  end

  # -- Query Predicates -------------------------------------------------------

  # Checks if a title is configured for the section.
  #
  # @return [Boolean] True if a title is present.
  def title?
    @title.present?
  end

  # Checks if a secondary description is configured for the section.
  #
  # @return [Boolean] True if a description is present.
  def description?
    @description.present?
  end

  # Checks if a contextual header action is configured for the section.
  #
  # @return [Boolean] True if an action map is present.
  def action?
    @action.present?
  end

  # -- Accessibility Helpers --------------------------------------------------

  # Generates a slug-based ID for accessibility relations.
  #
  # @return [String, nil] Unique DOM ID slug for description elements, or nil if no title is present.
  def description_dom_id
    "#{@title.parameterize}-desc" if title?
  end

end
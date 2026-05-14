# frozen_string_literal: true

# Component responsible for rendering a recent activity list with optional
# action header and configurable column layout.
#
# This component aggregates multiple activity item blocks and provides an
# empty-state query for conditional rendering.
#
# @author Moisés Reis

class Groups::RecentActivityComponent < ApplicationComponent

  # ==========================================================================
  # COMPOSITION
  # ==========================================================================

  # Defines the slot for individual activity records.
  renders_many :items, Blocks::ActivityItemComponent

  # ==========================================================================
  # INITIALIZATION
  # ==========================================================================

  # @param title [String] The heading for the activity section.
  # @param action [Hash, nil] Optional configuration for a header link (e.g., { label: "Ver todos", path: "/logs" }).
  # @param columns [Integer] Number of columns for the grid layout (defaults to 1).
  def initialize(title:, action: nil, columns: 1)
    @title   = title
    @action  = action
    @columns = columns
  end

  # ==========================================================================
  # QUERY METHODS
  # ==========================================================================

  # Checks if any activity items have been provided to the slots.
  # @return [Boolean]
  def empty?
    items.empty?
  end
end

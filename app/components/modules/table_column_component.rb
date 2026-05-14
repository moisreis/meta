# frozen_string_literal: true

# Component responsible for rendering a table column header with optional icon
# and description metadata.
#
# This component standardizes column header presentation across table-based UI
# structures.
#
# @author Moisés Reis

class Modules::TableColumnComponent < ApplicationComponent

  # ==========================================================================
  # INITIALIZATION
  # ==========================================================================

  # @param label [String] The visible text for the column header.
  # @param icon [String, nil] The name of the icon to display alongside the label.
  # @param description [String, nil] Tooltip or helper text describing the column's data.
  def initialize(label:, icon: nil, description: nil)
    @label       = label
    @icon        = icon
    @description = description
  end

  # ==========================================================================
  # QUERY METHODS
  # ==========================================================================

  # Checks if an icon name is present.
  # @return [Boolean]
  def icon?
    @icon.present?
  end

  # Checks if a description string is present.
  # @return [Boolean]
  def description?
    @description.present?
  end
end

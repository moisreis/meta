# frozen_string_literal: true

# Component responsible for rendering a table-based list view with support for
# column and row composition, optional header metadata, and empty-state handling.
#
# This component standardizes list/table presentation across grouped UI sections.
#
# @author Moisés Reis

class Groups::TableListComponent < ApplicationComponent

  # ==========================================================================
  # COMPOSITION
  # ==========================================================================

  # Defines the headers for the table.
  renders_many :columns, Modules::TableColumnComponent

  # Defines the individual data rows for the table.
  renders_many :rows,    Modules::TableRowComponent

  # ==========================================================================
  # INITIALIZATION
  # ==========================================================================

  # @param title [String, nil] The heading for the table section.
  # @param description [String, nil] Optional subtitle or explanatory text.
  # @param action [Hash, nil] Optional header link (e.g., { label: "Ver todos", path: "/items" }).
  # @param collection [Enumerable] The data collection to determine empty states and counts.
  def initialize(title: nil, description: nil, action: nil, collection: [])
    @title       = title
    @description = description
    @action      = action
    @collection  = collection
  end

  # ==========================================================================
  # QUERY METHODS
  # ==========================================================================

  # Checks if the provided collection has no records.
  # @return [Boolean]
  def empty?
    @collection.none?
  end

  # Returns the total number of items in the collection.
  # @return [Integer]
  def row_count
    @collection.size
  end
end

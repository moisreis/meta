# frozen_string_literal: true

# Component responsible for rendering a chart container with title, data source,
# optional metadata, and empty-state awareness.
#
# This component acts as a structural wrapper around chart rendering helpers
# and external chart builders.
#
# @author Moisés Reis

class Blocks::ChartComponent < ApplicationComponent

  # ==========================================================================
  # INITIALIZATION
  # ==========================================================================

  # @param title [String] The heading for the chart section.
  # @param data_source [Enumerable] The collection of data to be visualized.
  # @param id [String, nil] Unique identifier for the chart container.
  # @param meta [String, nil] Optional metadata or subtitle information.
  def initialize(title:, data_source:, id: nil, meta: nil)
    @title       = title
    @data_source = data_source
    @id          = id
    @meta        = meta
  end

  # ==========================================================================
  # QUERY METHODS
  # ==========================================================================

  private

  # Checks if the data source contains any records to render.
  # @return [Boolean]
  def data?
    @data_source.any?
  end
end

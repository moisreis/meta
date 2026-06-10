# frozen_string_literal: true

# app/components/blocks/chart_component.rb
#
# Component responsible for rendering a chart container with title, data source,
# optional metadata, and empty-state awareness.
#
# This component acts as a structural wrapper around chart rendering helpers
# and external chart builders.
#
# @author  Moisés Reis

class Blocks::ChartComponent < ApplicationComponent

  # == Class Methods ==========================================================

  # Initializes the chart component wrapper with data assets and metadata hooks.
  #
  # @param title [String] The heading for the chart section.
  # @param data_source [Enumerable] The collection of data to be visualized.
  # @param id [String, nil] Unique identifier for the chart container.
  # @param meta [String, nil] Optional metadata or subtitle information.
  # @return [Blocks::ChartComponent]
  def initialize(title:, data_source:, id: nil, meta: nil)
    @title       = title
    @data_source = data_source
    @id          = id
    @meta        = meta
  end


  private


  # == Private Methods ========================================================

  # -- Query Predicates -------------------------------------------------------

  # Checks if the data source contains any records to render.
  #
  # @return [Boolean] True if the collection has records available.
  def data?
    @data_source.any?
  end

end
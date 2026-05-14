# frozen_string_literal: true

# Component responsible for rendering chart groups with validated chart types
# and standardized palette application.
#
# This component acts as a safety layer over chart rendering helpers, ensuring
# only permitted chart types are executed and consistent styling is applied.
#
# @author Moisés Reis

class Groups::ChartListComponent < ApplicationComponent

  # ==========================================================================
  # CONSTANTS
  # ==========================================================================

  # List of Chartkick-compatible helper methods allowed for execution.
  PERMITTED_TYPES = %w[
    bar_chart
    line_chart
    pie_chart
    area_chart
    column_chart
  ].freeze

  # ==========================================================================
  # INITIALIZATION
  # ==========================================================================

  # @param chart_type [String, Symbol] The helper method to call (e.g., :pie_chart).
  # @param data_source [Object] The data payload for the chart.
  # @param chart_title [String] Title displayed above the chart.
  # @param palette [Symbol] The color theme from ChartPalettes.
  # @param chart_options [Hash] Additional Chartkick library options.
  # @param chart_id [String, nil] Unique HTML ID; generates a random hex if nil.
  def initialize(chart_type:, data_source:, chart_title:,
                 palette: :default, chart_options: {}, chart_id: nil)
    @chart_type    = chart_type.to_s
    @data_source   = data_source
    @chart_title   = chart_title
    @chart_options = palette ? chart_options.merge(colors: ChartPalettes.css(palette)) : chart_options
    @chart_id      = chart_id || "chart-#{SecureRandom.hex(6)}"
  end

  # ==========================================================================
  # PRIVATE METHODS
  # ==========================================================================

  private

  # Executes the dynamic helper call after validation.
  #
  # @raise [ArgumentError] If the requested chart_type is not in PERMITTED_TYPES.
  # @return [ActiveSupport::SafeBuffer] The rendered chart HTML.
  def chart_output
    raise ArgumentError, "Unpermitted chart type: #{@chart_type}" unless permitted_type?

    helpers.public_send(@chart_type, @data_source, id: @chart_id, **@chart_options)
  end

  # @return [Boolean]
  def permitted_type?
    PERMITTED_TYPES.include?(@chart_type)
  end
end

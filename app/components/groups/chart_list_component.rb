# app/components/chart_list_component.rb
#
# Renders a chart inside the standardized ChartComponent container.
# Dynamically dispatches the configured chart helper method while
# preserving a consistent dashboard presentation layer.
#
# Supported chart helpers depend on the charting library in use
# (e.g. line_chart, pie_chart, column_chart).
#
# Usage:
#
#   <%= render(
#         ChartListComponent.new(
#           data_source: @revenues,
#           chart_title: "Revenue",
#           chart_type: :line_chart,
#           chart_meta: "2026",
#           chart_options: {
#             height: "300px"
#           }
#         )
#       ) %>
#
# @author Moisés Reis
class Groups::ChartListComponent < ApplicationComponent
  # ===========================================================
  #                       INITIALIZATION
  # ===========================================================

  # @param data_source [Enumerable]
  # @param chart_title [String]
  # @param chart_type [Symbol, String]
  # @param chart_options [Hash]
  # @param chart_id [String, nil]
  # @param chart_meta [String, nil]
  def initialize(
    data_source:,
    chart_title:,
    chart_type:,
    chart_options: {},
    chart_id: nil,
    chart_meta: nil
  )
    @data_source   = data_source
    @chart_title   = chart_title
    @chart_type    = chart_type.to_sym
    @chart_options = chart_options
    @chart_id      = chart_id || default_chart_id
    @chart_meta    = chart_meta
  end

  private

  attr_reader :data_source,
              :chart_title,
              :chart_type,
              :chart_options,
              :chart_id,
              :chart_meta

  # @return [String]
  def default_chart_id
    "chart-#{SecureRandom.hex(6)}"
  end

  # @return [String]
  def rendered_chart
    helpers.public_send(
      chart_type,
      data_source,
      id: chart_id,
      **chart_options
    )
  end
end
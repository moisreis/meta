# app/components/chart_component.rb
#
# Renders a reusable chart container with a standardized header,
# optional metadata, and empty-state handling.
#
# Usage:
#
#   <%= render(
#         ChartComponent.new(
#           chart_title: "Revenue",
#           data_source: @revenues,
#           chart_id: "revenue-chart",
#           chart_meta: "2026"
#         )
#       ) do %>
#     <%= line_chart @revenues %>
#   <% end %>
#
# @author Moisés Reis
class Modules::ChartComponent < ApplicationComponent
  # ===========================================================
  #                       INITIALIZATION
  # ===========================================================

  # @param chart_title [String]
  # @param data_source [Enumerable]
  # @param chart_id [String, nil]
  # @param chart_meta [String, nil]
  def initialize(
    chart_title:,
    data_source:,
    chart_id: nil,
    chart_meta: nil
  )
    @chart_title = chart_title
    @data_source = data_source
    @chart_id    = chart_id
    @chart_meta  = chart_meta
  end

  private

  attr_reader :chart_title,
              :data_source,
              :chart_id,
              :chart_meta

  # @return [Boolean]
  def data_available?
    data_source.any?
  end
end
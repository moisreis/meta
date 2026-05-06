# app/components/groups/chart_list_component.rb
#
# Renders a specific chart type inside a Groups::ChartComponent container.
# Delegates the actual chart markup to the appropriate helper method dynamically.
#
# Security: chart_type is validated against PERMITTED_TYPES before dispatch.
# Only helpers that are explicitly listed may be called.
class Groups::ChartListComponent < ApplicationComponent

  # Extend this list as new chart helper methods are added.
  PERMITTED_TYPES = %w[
    bar_chart
    line_chart
    pie_chart
    area_chart
    column_chart
  ].freeze

# @param chart_type    [String]      Name of the helper method that renders the chart.
# @param data_source   [#any?]       Collection or URL providing the chart data.
# @param chart_title   [String]      Heading text displayed in the chart header.
# @param chart_options [Hash]        Optional visual customization passed to the helper.
# @param chart_id      [String, nil] Stable DOM id. Auto-generated when omitted.
# After
# In Groups::ChartListComponent#initialize
def initialize(chart_type:, data_source:, chart_title:,
               palette: :default, chart_options: {}, chart_id: nil)
  @chart_type    = chart_type.to_s
  @data_source   = data_source
  @chart_title   = chart_title
  @chart_options = palette ? chart_options.merge(colors: ChartPalettes.css(palette)) : chart_options
  @chart_id      = chart_id || "chart-#{SecureRandom.hex(6)}"
end

  private

  # @return [String] The rendered chart HTML from the resolved helper.
  # @raise  [ArgumentError] When chart_type is not in PERMITTED_TYPES.
  def chart_output
    raise ArgumentError, "Unpermitted chart type: #{@chart_type}" unless permitted_type?

    helpers.public_send(@chart_type, @data_source, id: @chart_id, **@chart_options)
  end

  def permitted_type?
    PERMITTED_TYPES.include?(@chart_type)
  end
end
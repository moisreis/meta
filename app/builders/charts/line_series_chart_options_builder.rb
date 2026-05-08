# app/builders/charts/line_series_chart_options_builder.rb
#
# Builds standardized options for line-series chart visualizations.
# Designed for multi-series financial comparisons (portfolio vs benchmarks).
#
# RESPONSIBILITIES:
# - Normalize dataset structure (Chartkick-compatible)
# - Apply semantic palette (ChartPalettes)
# - Configure axes + tooltip defaults
#
# NON-RESPONSIBILITIES:
# - Data fetching
# - Aggregation logic
# - Domain calculations
#
# @author Project Team
module Charts
  class LineSeriesChartOptionsBuilder

    # @param data [Object] domain object exposing benchmark series
    def self.call(data)
      new(data).call
    end

    def initialize(data)
      @data = data
    end

    def call
      {
        colors: ChartPalettes.css(:line_series),
        library: base_library_options
      }
    end

    private

    def base_library_options
      {
        curveType: "function",
        legend: { position: "bottom" },
        hAxis: { textPosition: "out" },
        vAxis: { format: "percent" },
        focusTarget: "category"
      }
    end
  end
end
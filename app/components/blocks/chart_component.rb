# app/components/dashboard/chart_component.rb
#
# Renders a chart card with a header and a body.
# The chart itself is passed as a block and only rendered when data is present.
# When the collection is empty, a fallback message is shown instead.
class Blocks::ChartComponent < ApplicationComponent

  # @param title       [String]           Chart heading displayed in the header.
  # @param data_source [#any?]            Collection used to determine if data exists.
  # @param id          [String, nil]      Optional value for the data-chart-id attribute.
  # @param meta        [String, nil]      Optional secondary label (e.g. "2026", "Últ. 3 meses").
  def initialize(title:, data_source:, id: nil, meta: nil)
    @title       = title
    @data_source = data_source
    @id          = id
    @meta        = meta
  end

  private

  def data?
    @data_source.any?
  end
end
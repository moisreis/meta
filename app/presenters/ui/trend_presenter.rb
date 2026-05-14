# frozen_string_literal: true

# Provides UI presentation helpers and reusable rendering abstractions.
#
# This namespace groups presenter objects responsible for encapsulating
# reusable view rendering logic and presentation-specific formatting behavior.
#
# @author Moisés Reis

module Ui

  # Renders directional financial trend indicators.
  #
  # This presenter combines:
  # - trend classification
  # - numeric formatting
  # - directional iconography
  # - semantic styling
  #
  # Blank-state rendering behavior is delegated to {EmptyStatePresenter}.
  class TrendPresenter < BasePresenter

    # ==========================================================================
    # INITIALIZATION
    # ==========================================================================

    # Initializes the presenter and supporting rendering dependencies.
    #
    # @param view_context [ActionView::Base] Rails view context instance.
    def initialize(view_context)
      super

      @empty      = EmptyStatePresenter.new(view_context)
      @financial  = FinancialPresenter.new(view_context)
      @classifier = TrendClassifier.new
    end

    # ==========================================================================
    # PUBLIC METHODS
    # ==========================================================================

    # Renders a directional trend component.
    #
    # Supported formats:
    # - :currency
    # - :percentage
    #
    # Positive, negative, and stable values receive distinct:
    # - colors
    # - icons
    # - semantic styling
    #
    # @param value [Numeric, nil] Numeric value evaluated for trend rendering.
    # @param format [Symbol] Formatting strategy used for value presentation.
    # @return [ActiveSupport::SafeBuffer] Rendered HTML trend component.
    def render(value, format: :currency)
      return @empty.render if value.blank?

      trend           = @classifier.call(value)
      styles          = trend_styles.fetch(trend)
      formatted_value = format_value(value.abs, format)

      h.content_tag(
        :div,
        class: "flex items-center [&>span]:!font-medium gap-1 #{styles[:color]}"
      ) do
        h.concat(
          h.inline_svg_tag(
            "icons/#{styles[:icon]}.svg",
            class: "w-4 h-4 fill-current"
          )
        )

        h.concat(formatted_value)
      end
    end

    private

    # ==========================================================================
    # PRIVATE METHODS
    # ==========================================================================

    # Returns semantic style definitions for each trend type.
    #
    # @return [Hash<Symbol, Hash>] Trend style configuration map.
    def trend_styles
      {
        up: {
          color: "text-success-600 [&>span]:!text-success-600",
          icon: "trending-up"
        },
        down: {
          color: "text-danger-600 [&>span]:!text-danger-600",
          icon: "trending-down"
        },
        stale: {
          color: "text-muted [&>svg]:hidden",
          icon: "minus"
        }
      }
    end

    # Formats a trend value according to the selected presentation strategy.
    #
    # Supported formats:
    # - :currency
    # - :percentage
    #
    # @param value [Numeric] Absolute numeric value rendered for display.
    # @param format [Symbol] Formatting strategy identifier.
    # @return [ActiveSupport::SafeBuffer] Rendered formatted value.
    def format_value(value, format)
      case format
      when :percentage
        @financial.percentage(value)
      else
        @financial.currency(value)
      end
    end
  end
end

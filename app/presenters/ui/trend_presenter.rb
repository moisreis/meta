# frozen_string_literal: true

# app/presenters/ui/trend_presenter.rb
#
# Ui namespace containing presenters responsible for standardized UI rendering.
#
# Renders directional trend indicators with icons and semantic coloring.
#
# @author Moisés Reis
module Ui
  # =============================================================
  #               Ui::TrendPresenter
  # =============================================================
  #
  # Renders numeric values with directional icons (up/down/stale)
  # and semantic coloring to indicate positive, negative, or neutral trends.
  #
  class TrendPresenter < BasePresenter

    # =============================================================
    #                      1. INITIALIZATION
    # =============================================================

    # @param view_context [ActionView::Base] Rails view context providing helper methods.
    def initialize(view_context)
      super
      @empty = EmptyStatePresenter.new(view_context)
      @financial = FinancialPresenter.new(view_context)
      @classifier = TrendClassifier.new
    end

    # =============================================================
    #                    2a. RENDER
    # =============================================================

    # Renders a value with directional icon and semantic coloring.
    #
    # @param value [Numeric, nil] The change value to evaluate
    # @param format [Symbol] Output format: :currency or :percentage (default: :currency)
    # @return [ActiveSupport::SafeBuffer] HTML flex container with icon and formatted value,
    #                                      or empty-state placeholder if value is blank
    #
    # @example Positive trend with currency formatting
    #   presenter = Ui::TrendPresenter.new(view_context)
    #   presenter.render(250.50)
    #   # => <div class="flex items-center [&>span]:!font-medium gap-1 text-success-600 [&>span]:!text-success-600">
    #   #      <svg>...</svg>
    #   #      <span>R$250,50</span>
    #   #    </div>
    #
    # @example Negative trend with percentage formatting
    #   presenter.render(-12.5, format: :percentage)
    #   # => <div class="flex items-center [&>span]:!font-medium gap-1 text-danger-600 [&>span]:!text-danger-600">
    #   #      <svg>...</svg>
    #   #      <span>12,50%</span>
    #   #    </div>
    #
    def render(value, format: :currency)
      return @empty.render if value.blank?

      trend = @classifier.call(value)
      styles = trend_styles[trend]
      formatted_value = format_value(value.abs, format)

      h.content_tag(:div, class: "flex items-center [&>span]:!font-medium gap-1 #{styles[:color]}") do
        h.concat h.inline_svg_tag("icons/#{styles[:icon]}.svg", class: "w-4 h-4 fill-current")
        h.concat formatted_value
      end
    end

    private

    # =============================================================
    #              3a. TREND CLASSIFICATION STYLES
    # =============================================================

    # Returns styling configuration for each trend direction.
    #
    # @return [Hash] Mapping of trend symbols to color and icon configuration
    def trend_styles
      {
        up: { color: "text-success-600 [&>span]:!text-success-600", icon: "trending-up" },
        down: { color: "text-danger-600 [&>span]:!text-danger-600", icon: "trending-down" },
        stale: { color: "text-muted [&>svg]:hidden", icon: "minus" }
      }
    end

    # Formats a numeric value according to the specified format.
    #
    # @param value [Numeric] The value to format (expected to be positive/absolute)
    # @param format [Symbol] Output format: :currency or :percentage
    # @return [ActiveSupport::SafeBuffer] Formatted value span element
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

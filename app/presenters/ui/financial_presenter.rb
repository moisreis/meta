# frozen_string_literal: true

# Provides UI presentation helpers and reusable rendering abstractions.
#
# This namespace groups presenter objects responsible for encapsulating
# reusable view rendering logic and presentation-specific formatting behavior.
#
# @author Moisés Reis

module Ui

  # Renders formatted financial and numeric presentation values.
  #
  # This presenter provides standardized formatting helpers for:
  # - currency values
  # - quotas
  # - percentages
  # - numeric values
  # - financial trends
  #
  # Blank-state rendering behavior is delegated to {EmptyStatePresenter}.
  class FinancialPresenter < BasePresenter

    # ==========================================================================
    # CONSTANTS
    # ==========================================================================

    # Shared CSS utility classes applied to formatted financial values.
    #
    # @return [String] CSS class list used for financial rendering.
    BASE_CLASSES = "line-clamp-2 font-mono".freeze

    # ==========================================================================
    # INITIALIZATION
    # ==========================================================================

    # Initializes the presenter.
    #
    # @param view_context [ActionView::Base] Rails view context instance.
    def initialize(view_context)
      super

      @empty = EmptyStatePresenter.new(view_context)
    end

    # ==========================================================================
    # PUBLIC METHODS
    # ==========================================================================

    # Renders a formatted currency value.
    #
    # Values are formatted using Brazilian Real conventions.
    #
    # @param value [Numeric, nil] Monetary value to render.
    # @return [ActiveSupport::SafeBuffer] Rendered HTML span element.
    def currency(value)
      return @empty.render if invalid?(value)

      formatted = h.number_to_currency(
        value,
        unit: "R$",
        separator: ",",
        delimiter: "."
      )

      h.content_tag(
        :span,
        formatted,
        class: BASE_CLASSES,
        scope: "row"
      )
    end

    # Renders a formatted quota value with high precision.
    #
    # Values are formatted using six decimal places.
    #
    # @param value [Numeric, nil] Quota value to render.
    # @return [ActiveSupport::SafeBuffer] Rendered HTML span element.
    def quota(value)
      return @empty.render if invalid?(value)

      formatted = h.number_to_currency(
        value,
        unit: "R$",
        separator: ",",
        delimiter: ".",
        precision: 6
      )

      h.content_tag(
        :span,
        formatted,
        class: BASE_CLASSES,
        scope: "row"
      )
    end

    # Renders a formatted numeric value.
    #
    # Insignificant trailing zeros are automatically removed.
    #
    # @param value [Numeric, nil] Numeric value to render.
    # @return [ActiveSupport::SafeBuffer] Rendered HTML span element.
    def number(value)
      return @empty.render if invalid?(value)

      formatted = h.number_with_precision(
        value,
        precision: 2,
        delimiter: ".",
        separator: ",",
        strip_insignificant_zeros: true
      )

      h.content_tag(
        :span,
        formatted,
        class: BASE_CLASSES,
        scope: "row"
      )
    end

    # Renders a formatted percentage value.
    #
    # @param value [Numeric, nil] Percentage value to render.
    # @param precision [Integer] Decimal precision used for formatting.
    # @return [ActiveSupport::SafeBuffer] Rendered HTML span element.
    def percentage(value, precision: 2)
      return @empty.render if invalid?(value)

      formatted = h.number_to_percentage(
        value,
        precision: precision,
        separator: ",",
        delimiter: "."
      )

      h.content_tag(
        :span,
        formatted,
        class: BASE_CLASSES,
        scope: "row"
      )
    end

    # Renders a financial trend indicator with directional styling.
    #
    # Positive, negative, and stable values receive distinct visual
    # representations and directional icons.
    #
    # Supported formats:
    # - :currency
    # - :percentage
    #
    # @param value [Numeric, nil] Financial value used for trend analysis.
    # @param format [Symbol] Rendering format used for value presentation.
    # @return [ActiveSupport::SafeBuffer] Rendered HTML trend component.
    def trend(value, format: :currency)
      return @empty.render if value.blank?

      trend_type = TrendClassifier.new.call(value)

      styles = {
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
      }.fetch(trend_type)

      formatted_value =
        if format == :percentage
          percentage(value.abs)
        else
          currency(value.abs)
        end

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

    # Determines whether a value should be treated as visually empty.
    #
    # Blank and zero-equivalent values are considered invalid for
    # financial rendering purposes.
    #
    # @param value [Object] Value evaluated for rendering eligibility.
    # @return [Boolean] True when the value should render as empty.
    def invalid?(value)
      value.blank? || (value.respond_to?(:zero?) && value.zero?)
    end
  end
end

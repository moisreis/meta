# frozen_string_literal: true

# app/presenters/ui/financial_presenter.rb
#
# Ui namespace containing presenters responsible for formatting UI-level values.
#
# Handles currency, quota, percentage, numeric formatting, and trend visualization.
#
# @author Moisés Reis
module Ui
  # =============================================================
  #              Ui::FinancialPresenter
  # =============================================================
  #
  # Provides consistent formatting for monetary, percentage, numeric,
  # and directional trend values used across UI components such as
  # tables and dashboards.
  #
  class FinancialPresenter < BasePresenter

    # =============================================================
    #                 1. CONSTANTS & CONFIGURATION
    # =============================================================

    BASE_CLASSES = "line-clamp-2 font-mono".freeze

    # =============================================================
    #                      2. INITIALIZATION
    # =============================================================

    # @param view_context [ActionView::Base] Rails view context providing helper methods.
    def initialize(view_context)
      super
      @empty = EmptyStatePresenter.new(view_context)
    end

    # =============================================================
    #                        3a. CURRENCY
    # =============================================================

    # Formats a monetary value in Brazilian currency format.
    #
    # @param value [Numeric, nil] Monetary value.
    # @return [ActiveSupport::SafeBuffer] Formatted currency span or empty-state element.
    def currency(value)
      return @empty.render if invalid?(value)

      formatted = h.number_to_currency(value, unit: "R$", separator: ",", delimiter: ".")
      h.content_tag(:span, formatted, class: BASE_CLASSES, scope: "row")
    end

    # =============================================================
    #                          3b. QUOTA
    # =============================================================

    # Formats a high-precision monetary quota value.
    #
    # @param value [Numeric, nil] Quota value.
    # @return [ActiveSupport::SafeBuffer] Formatted quota span or empty-state element.
    def quota(value)
      return @empty.render if invalid?(value)

      formatted = h.number_to_currency(
        value,
        unit: "R$",
        separator: ",",
        delimiter: ".",
        precision: 6
      )

      h.content_tag(:span, formatted, class: BASE_CLASSES, scope: "row")
    end

    # =============================================================
    #                         3c. NUMBER
    # =============================================================

    # Formats a generic numeric value with localization rules.
    #
    # @param value [Numeric, nil] Numeric value.
    # @return [ActiveSupport::SafeBuffer] Formatted numeric span or empty-state element.
    def number(value)
      return @empty.render if invalid?(value)

      formatted = h.number_with_precision(
        value,
        precision: 2,
        delimiter: ".",
        separator: ",",
        strip_insignificant_zeros: true
      )

      h.content_tag(:span, formatted, class: BASE_CLASSES, scope: "row")
    end

    # =============================================================
    #                       3d. PERCENTAGE
    # =============================================================

    # Formats a numeric value as a percentage.
    #
    # @param value [Numeric, nil] Percentage value.
    # @param precision [Integer] Number of decimal places.
    # @return [ActiveSupport::SafeBuffer] Formatted percentage span or empty-state element.
    def percentage(value, precision: 2)
      return @empty.render if invalid?(value)

      formatted = h.number_to_percentage(
        value,
        precision: precision,
        separator: ",",
        delimiter: "."
      )

      h.content_tag(:span, formatted, class: BASE_CLASSES, scope: "row")
    end

    # =============================================================
    #                        3e. TREND
    # =============================================================

    # Renders a color-coded trend indicator with icon and formatted absolute value.
    #
    # @param value [Numeric, nil] Value used to determine trend direction.
    # @param format [Symbol] Formatting mode (:currency or :percentage).
    # @return [ActiveSupport::SafeBuffer] HTML trend component or empty-state element.
    def trend(value, format: :currency)
      return @empty.render if value.blank?

      trend_type = TrendClassifier.new.call(value)

      styles = {
        up:    { color: "text-success-600 [&>span]:!text-success-600", icon: "trending-up" },
        down:  { color: "text-danger-600 [&>span]:!text-danger-600", icon: "trending-down" },
        stale: { color: "text-muted [&>svg]:hidden", icon: "minus" }
      }[trend_type]

      formatted_value =
        if format == :percentage
          percentage(value.abs)
        else
          currency(value.abs)
        end

      h.content_tag(:div, class: "flex items-center [&>span]:!font-medium gap-1 #{styles[:color]}") do
        h.concat h.inline_svg_tag("icons/#{styles[:icon]}.svg", class: "w-4 h-4 fill-current")
        h.concat formatted_value
      end
    end

    private

    # =============================================================
    #                    4a. VALIDATION LOGIC
    # =============================================================

    # Determines whether a value is invalid for display purposes.
    #
    # @param value [Object] Input value.
    # @return [Boolean] True if value is blank or numerically zero.
    def invalid?(value)
      value.blank? || (value.respond_to?(:zero?) && value.zero?)
    end
  end
end

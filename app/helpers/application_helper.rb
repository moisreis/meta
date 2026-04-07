# frozen_string_literal: true

# == ApplicationHelper
#
# @author Moisés Reis
# @project Meta Investimentos
# @added 11/25/2025
# @package Meta
# @category Helper
#
# @description
#   Provides utility methods that assist views and other components in presenting
#   data consistently and managing global application logic. This module contains
#   reusable functions for formatting numbers, generating UI elements, handling
#   flash messages, and creating sortable table columns.
#
# @example Basic usage in a view
#   <%= full_title("Dashboard") %>
#   # => "Dashboard | Financial Portfolio Manager"
#
#   <%= currency_format(1234.56) %>
#   # => "R$1.234,56"
#
#   <%= colored_percentage(15.5) %>
#   # => <span class="... text-body">15,5%</span>
#
# @see INFO_CARD_COLORS for the color palette used across info card components
#
module ApplicationHelper
  # == full_title
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category View Helper
  #
  # @description
  #   Constructs the full page title for the browser tab by combining a specific
  #   page title with the base application name.
  #
  # @param page_title [String] The specific title of the current page
  # @return [String] The complete page title, or just the base title if page_title is blank
  #
  # @example With a page title
  #   full_title("User Profile")
  #   # => "User Profile | Financial Portfolio Manager"
  #
  # @example With a blank title
  #   full_title("")
  #   # => "Financial Portfolio Manager"
  #
  def full_title(page_title)
    base_title = "Financial Portfolio Manager"

    if page_title.blank?
      base_title
    else
      "#{page_title} | #{base_title}"
    end
  end

  # == currency_format
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Formatting
  #
  # @description
  #   Formats a numerical value into a Brazilian currency string (R$) with proper
  #   decimal separator (comma) and thousands delimiter (period).
  #
  # @param amount [Numeric] The number to format as currency
  # @return [String] The formatted currency string (e.g., "R$1.234,56")
  #
  # @example Format a monetary value
  #   currency_format(1234.56)
  #   # => "R$1.234,56"
  #
  # @example Format zero
  #   currency_format(0)
  #   # => "R$0,00"
  #
  def currency_format(amount)
    number_to_currency(
      amount,
      unit: "R$",
      separator: ",",
      delimiter: ".",
      locale: :pt
    )
  end

  # == flash_class_for
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category UI Helper
  #
  # @description
  #   Maps Rails flash message types to corresponding CSS badge classes for
  #   consistent visual styling. Success messages appear green, errors appear red,
  #   warnings appear yellow, and info messages appear blue.
  #
  # @param flash_type [Symbol, String] The type of flash message
  #   (e.g., :notice, :alert, :error, :success, :warning, :info)
  # @return [String] The CSS class name for styling the flash message badge
  #
  # @example Success notice
  #   flash_class_for(:notice)
  #   # => "badge-success"
  #
  # @example Error alert
  #   flash_class_for(:error)
  #   # => "badge-danger"
  #
  # @example Unknown type
  #   flash_class_for(:custom)
  #   # => "custom"
  #
  def flash_class_for(flash_type)
    case flash_type.to_s
    when "success", "notice"
      "badge-success"
    when "error", "alert"
      "badge-danger"
    when "warning"
      "badge-warning"
    when "info"
      "badge-info"
    else
      flash_type.to_s
    end
  end

  # == sortable
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Table Helper
  #
  # @description
  #   Generates an HTML link that makes a table column sortable using Ransack
  #   parameters. Automatically toggles sort direction (ascending/descending)
  #   and displays the appropriate arrow icon based on the current sort state.
  #
  # @param name [String] The display name for the column header
  # @param column [Symbol, String] The database column name to sort by
  # @param custom_icon [String] The filename of the SVG icon to display (without extension)
  # @return [String] HTML link element with sort functionality and arrow icon
  #
  # @example Create a sortable column header
  #   sortable("Fund Name", :fund_name, "sort")
  #   # => <a href="?q[s]=fund_name asc"><div class="flex flex-row gap-1 items-center">Fund Name <svg>...</svg></div></a>
  #
  # @see params[:q][:s] Ransack sort parameter format
  #
  def sortable(name, column, custom_icon)
    current_sort_key = params.dig(:q, :s)
    current_column, current_direction = current_sort_key&.split || [ nil, "asc" ]

    direction =
      if current_column == column.to_s
        current_direction == "asc" ? "desc" : "asc"
      else
        "asc"
      end

    new_sort = "#{column} #{direction}"

    icon =
      if current_column != column.to_s
        "arrow-down"
      elsif current_direction == "asc"
        "arrow-up"
      else
        "arrow-down"
      end

    link_to params.permit!.merge(q: (params[:q] || {}).merge(s: new_sort)) do
      content_tag(:div, class: "flex flex-row gap-1 items-center") do
        safe_join([
                    name,
                    inline_svg_tag("icons/#{icon}.svg", class: "size-3 stroke-body")
                  ])
      end
    end
  end

  # Available shade levels for proportional color intensity calculations.
  # Used by {#shade_for_value} to map numeric values to Tailwind shade classes.
  #
  # @return [Array<Integer>] Fixed array of shade values from 50 to 900
  SHADE_STEPS = [ 50, 100, 200, 300, 400, 500, 600, 700, 800, 900 ].freeze

  # == shade_for_value
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Color Helper
  #
  # @description
  #   Calculates a Tailwind shade level based on the proportional size of a value
  #   relative to a maximum. Higher values receive stronger color intensity.
  #   Useful for creating heat maps or proportional color coding in tables.
  #
  # @param value [Numeric] The value to calculate the shade for
  # @param max_value [Numeric] The maximum value used as the upper bound (default: 100,000)
  # @return [Integer] The shade level (50, 100, 200, ..., 900)
  #
  # @example Calculate shade for a moderate value
  #   shade_for_value(50_000, max_value: 100_000)
  #   # => 500
  #
  # @example Calculate shade for zero or negative
  #   shade_for_value(0)
  #   # => 50
  #
  # @example Calculate shade exceeding maximum
  #   shade_for_value(200_000, max_value: 100_000)
  #   # => 900
  #
  def shade_for_value(value, max_value: 100_000)
    return 50 if value.to_f <= 0

    v = [ value.to_f, max_value ].min
    ratio = v / max_value
    index = (ratio * (SHADE_STEPS.size - 1)).round

    SHADE_STEPS[index]
  end

  # == Shared helpers ==========================================================

  # == valid_nonzero_number?
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Validation
  #
  # @description
  #   Validates that a value is present, responds to numeric conversion, and
  #   is not equal to zero. Used as a guard clause before rendering colored
  #   numerical displays.
  #
  # @param value [Object] The value to validate
  # @return [Boolean] true if the value is present, numeric, and non-zero
  #
  # @example Valid number
  #   valid_nonzero_number?(15.5)
  #   # => true
  #
  # @example Zero value
  #   valid_nonzero_number?(0)
  #   # => false
  #
  # @example Nil value
  #   valid_nonzero_number?(nil)
  #   # => false
  #
  def valid_nonzero_number?(value)
    value.present? && value.respond_to?(:to_f) && value.to_f != 0
  end

  # == sign_color_class
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Color Helper
  #
  # @description
  #   Returns a Tailwind CSS text color class based on the sign of a numeric value.
  #   Negative values appear in red, zero in alert orange, and positive in the
  #   default body color.
  #
  # @param numeric_value [Numeric] The number to evaluate
  # @return [String] CSS class name for text coloring
  #
  # @example Positive value
  #   sign_color_class(100)
  #   # => "text-body"
  #
  # @example Negative value
  #   sign_color_class(-50)
  #   # => "text-danger-600"
  #
  # @example Zero value
  #   sign_color_class(0)
  #   # => "text-alert-600"
  #
  def sign_color_class(numeric_value)
    return "text-danger-600"  if numeric_value.negative?
    return "text-alert-600" if numeric_value == 0
    "text-body" if numeric_value.positive?
  end

  # == colored_base_classes
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category UI Helper
  #
  # @description
  #   Returns the base CSS classes used by all colored display helpers
  #   ({#colored_currency}, {#colored_numerical}, {#colored_percentage}).
  #   Provides consistent styling with flexbox layout, monospace font, and
  #   rounded badge appearance.
  #
  # @param additional_class [String] Extra CSS classes to append (default: "")
  # @return [String] Combined CSS class string
  #
  # @example Base classes only
  #   colored_base_classes
  #   # => "inline-flex items-center justify-center gap-1 whitespace-nowrap rounded-base uppercase font-mono text-sm font-medium"
  #
  # @example With additional class
  #   colored_base_classes("ml-2")
  #   # => "inline-flex items-center justify-center gap-1 whitespace-nowrap rounded-base uppercase font-mono text-sm font-medium ml-2"
  #
  def colored_base_classes(additional_class = "")
    [
      "inline-flex items-center justify-center gap-1 whitespace-nowrap rounded-base uppercase font-mono text-sm font-medium",
      additional_class
    ].join(" ")
  end

  # == colored_currency
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Formatting
  #
  # @description
  #   Renders a currency amount in a colored badge with semantic coloring based
  #   on the value's sign. Returns "Sem dados" (No data) for zero, nil, or
  #   invalid values. Positive values use the default text color, negative values
  #   appear in red.
  #
  # @param value [Numeric] The amount to format and display
  # @param additional_class [String] Extra CSS classes to append (default: "")
  # @return [String] HTML span element with formatted currency and color class
  #
  # @example Positive amount
  #   colored_currency(1500.50)
  #   # => <span class="... text-body">R$ 1.500,50</span>
  #
  # @example Negative amount
  #   colored_currency(-200)
  #   # => <span class="... text-danger-600">R$ -200,00</span>
  #
  # @example Zero or nil
  #   colored_currency(0)
  #   # => <span class="badge badge-alert">Sem dados</span>
  #
  # @see #valid_nonzero_number?
  # @see #sign_color_class
  # @see #colored_base_classes
  #
  def colored_currency(value, additional_class = "")
    return content_tag(:span, "Sem dados", class: "badge badge-alert") unless valid_nonzero_number?(value)

    numeric_value = value.to_f

    content_tag(
      :span,
      number_to_currency(value, unit: "R$ ", separator: ",", delimiter: "."),
      class: [
        colored_base_classes(additional_class),
        sign_color_class(numeric_value)
      ].join(" ")
    )
  end

  # == colored_numerical
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Formatting
  #
  # @description
  #   Renders a numerical value with one decimal place in a colored badge with
  #   semantic coloring based on the value's sign. Returns "Sem dados" (No data)
  #   for zero, nil, or invalid values.
  #
  # @param value [Numeric] The number to format and display
  # @param additional_class [String] Extra CSS classes to append (default: "")
  # @return [String] HTML span element with formatted number and color class
  #
  # @example Display a quantity
  #   colored_numerical(42.7)
  #   # => <span class="... text-body">42,7</span>
  #
  # @example Negative value
  #   colored_numerical(-5.3)
  #   # => <span class="... text-danger-600">-5,3</span>
  #
  # @see #valid_nonzero_number?
  # @see #sign_color_class
  # @see #colored_base_classes
  #
  def colored_numerical(value, additional_class = "")
    return content_tag(:span, "Sem dados", class: "badge badge-alert") unless valid_nonzero_number?(value)

    numeric_value = value.to_f
    formatted_value = number_with_precision(numeric_value, precision: 1)

    content_tag(
      :span,
      formatted_value,
      class: [
        colored_base_classes(additional_class),
        sign_color_class(numeric_value)
      ].join(" ")
    )
  end

  # == colored_percentage
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Formatting
  #
  # @description
  #   Renders a percentage value with one decimal place in a colored badge with
  #   semantic coloring based on the value's sign. Returns "Sem dados" (No data)
  #   for zero, nil, or invalid values. Appends a "%" symbol to the formatted number.
  #
  # @param value [Numeric] The percentage value to format (e.g., 15.5 for 15.5%)
  # @param additional_class [String] Extra CSS classes to append (default: "")
  # @return [String] HTML span element with formatted percentage and color class
  #
  # @example Positive percentage
  #   colored_percentage(15.5)
  #   # => <span class="... text-body">15,5%</span>
  #
  # @example Negative percentage
  #   colored_percentage(-3.2)
  #   # => <span class="... text-danger-600">-3,2%</span>
  #
  # @see #valid_nonzero_number?
  # @see #sign_color_class
  # @see #colored_base_classes
  #
  def colored_percentage(value, additional_class = "")
    return content_tag(:span, "Sem dados", class: "badge badge-alert") unless valid_nonzero_number?(value)

    numeric_value = value.to_f
    formatted_value = number_with_precision(numeric_value, precision: 1)

    content_tag(
      :span,
      "#{formatted_value}%",
      class: [
        colored_base_classes(additional_class),
        sign_color_class(numeric_value)
      ].join(" ")
    )
  end

  # == formatted_timestamp
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Formatting
  #
  # @description
  #   Formats a date/time object into a readable string and wraps it in a styled
  #   HTML span element. Uses Brazilian date format (DD/MM/YYYY) by default but
  #   accepts a custom formatter lambda for alternative formats.
  #
  # @param datetime [DateTime, Time, Date] The date/time object to format
  # @param formatter [Proc] Custom formatting lambda (default: strftime "%d/%m/%Y")
  # @return [String] HTML span with formatted date, or "Sem dados" if datetime is nil
  #
  # @example Default formatting
  #   formatted_timestamp(Date.new(2025, 1, 15))
  #   # => <span class="font-mono">15/01/2025</span>
  #
  # @example Custom formatter
  #   formatted_timestamp(Time.now, formatter: ->(t) { t.strftime("%B %Y") })
  #   # => <span class="font-mono">January 2025</span>
  #
  # @example Nil value
  #   formatted_timestamp(nil)
  #   # => <span class="badge badge-alert">Sem dados</span>
  #
  def formatted_timestamp(datetime, formatter: ->(t) { t.strftime("%d/%m/%Y") })
    return content_tag(:span, "Sem dados", class: "badge badge-alert") unless datetime.present?

    formatted = formatter.call(datetime)

    content_tag(:span, formatted, class: "font-mono")
  end

  # == standard_currency
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Formatting
  #
  # @description
  #   Displays a currency amount with standard Brazilian formatting in a
  #   monospaced font span. Unlike {#colored_currency}, this method does not
  #   apply semantic coloring based on the value's sign.
  #
  # @param value [Numeric] The amount to format
  # @param additional_class [String] Extra CSS classes to append (default: "")
  # @return [String] HTML span with formatted currency value
  #
  # @example Format an amount
  #   standard_currency(2500.75)
  #   # => <span class="font-mono ">R$ 2.500,75</span>
  #
  # @see #currency_format for a simpler string-only version
  #
  def standard_currency(value, additional_class = "")
    content_tag(
      :span,
      number_to_currency(value, unit: "R$ ", separator: ",", delimiter: "."),
      class: "font-mono #{additional_class}"
    )
  end

  # == precision_format
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Formatting
  #
  # @description
  #   Formats a number to a specific number of decimal places and wraps it in a
  #   monospaced font span for consistent alignment in tables and data displays.
  #   Uses Brazilian number formatting (comma as decimal separator, period as
  #   thousands delimiter).
  #
  # @param number [Numeric] The value to format
  # @param precision [Integer] Number of decimal places to display (default: 2)
  # @return [String] HTML span with formatted number
  #
  # @example Default precision (2 decimals)
  #   precision_format(1234.5)
  #   # => <span class="font-mono">1.234,50</span>
  #
  # @example Custom precision
  #   precision_format(99.999, precision: 3)
  #   # => <span class="font-mono">99,999</span>
  #
  def precision_format(number, precision: 2)
    formatted_number = number_with_precision(
      number,
      precision: precision,
      separator: ",",
      delimiter: "."
    )

    content_tag(:span, formatted_number, class: "font-mono")
  end
end

# == INFO_CARD_COLORS
#
# @author Moisés Reis
# @project Meta Investimentos
# @category Constants
#
# @description
#   Color palette configuration for info card components. Defines Tailwind CSS
#   classes for different semantic color variants used across the application.
#   Each variant includes background, icon background, border, text, and SVG
#   stroke colors.
#
# @return [Hash<String, Hash<Symbol, String>>] Nested hash mapping color names
#   to their CSS class configurations
#
# @example Access primary color classes
#   INFO_CARD_COLORS["primary"][:bg]
#   # => "bg-primary-50"
#
#   INFO_CARD_COLORS["success"][:text]
#   # => "text-success-600"
#
# @example Available color variants
#   INFO_CARD_COLORS.keys
#   # => ["primary", "success", "secondary", "quaternary", "danger"]
#
# @note This constant is frozen to prevent accidental modifications at runtime.
#
INFO_CARD_COLORS = {
  "primary" => {
    bg: "bg-primary-50",
    icon_bg: "bg-primary-600",
    border: "border-primary-200",
    text: "text-primary-600",
    stroke: "stroke-primary-600"
  },
  "success" => {
    bg: "bg-success-50",
    icon_bg: "bg-success-600",
    border: "border-success-200",
    text: "text-success-600",
    stroke: "stroke-success-600"
  },
  "secondary" => {
    bg: "bg-secondary-50",
    icon_bg: "bg-secondary-600",
    border: "border-secondary-200",
    text: "text-secondary-600",
    stroke: "stroke-secondary-600"
  },
  "quaternary" => {
    bg: "bg-quaternary-50",
    icon_bg: "bg-quaternary-600",
    border: "border-quaternary-200",
    text: "text-quaternary-600",
    stroke: "stroke-quaternary-600"
  },
  "danger" => {
    bg: "bg-danger-50",
    icon_bg: "bg-danger-600",
    border: "border-danger-200",
    text: "text-danger-600",
    stroke: "stroke-danger-600"
  }
}.freeze

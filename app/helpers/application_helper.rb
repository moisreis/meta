# frozen_string_literal: true

# == ApplicationHelper
#
# @author Moisés Reis
# @project Meta Investimentos
# @added 11/25/2025
# @package Meta
# @category Helpers
#
# @description
#   Contains utility methods that assist views and other components in presenting
#   data consistently and managing global application logic. It simplifies HTML
#   templates by handling formatting and UI element generation.
#
# @example Usage in a view
#   full_title("Dashboard")
#   # => "Dashboard | Financial Portfolio Manager"
#
module ApplicationHelper

  # Returns a memoized instance of a UI presenter
    def ui(presenter_name)
      @ui_presenters ||= {}
      @ui_presenters[presenter_name] ||= "Ui::#{presenter_name.to_s.classify}Presenter".constantize.new(self)
    end

  # == SHADE_STEPS
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Constants
  #
  # @description
  #   Defines a fixed list of numeric shade levels used to determine color intensity.
  #
  # @return [Array<Integer>] The list of available shade steps
  #
  # @example Usage
  #   SHADE_STEPS.first
  #   # => 50
  #
  SHADE_STEPS = [50, 100, 200, 300, 400, 500, 600, 700, 800, 900].freeze

  # == full_title
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Read
  #
  # @description
  #   Constructs the full page title for the browser tab by combining a specific
  #   page title with the base application name.
  #
  # @param page_title [String] The specific title of the current page
  # @return [String] The concatenated title or base title if empty
  #
  # @example With title
  #   full_title("Users")
  #   # => "Users | Financial Portfolio Manager"
  #
  # @example Without title
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
  #   Formats numerical data into a standard Brazilian currency string (R$).
  #   It adds the currency symbol, comma separator, and two decimal places.
  #
  # @param amount [Numeric] The number value to be formatted
  # @return [String] The formatted currency string
  #
  # @example Basic usage
  #   currency_format(1234.56)
  #   # => "R$1.234,56"
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
  #   Maps Rails flash message types to corresponding CSS classes.
  #   Ensures semantic coloring for success, error, and info alerts.
  #
  # @param flash_type [Symbol] The type of flash message
  # @return [String] The CSS class name
  #
  # @example Success message
  #   flash_class_for(:notice)
  #   # => "badge-success"
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
  # @category UI Helper
  #
  # @description
  #   Generates an HTML link that makes a table column sortable using Ransack
  #   parameters. It toggles direction and updates the visual icon.
  #
  # @param name [String] The display name for the column header
  # @param column [Symbol] The database column name to sort by
  # @param custom_icon [String] The filename of the SVG icon
  # @return [String] HTML safe link string
  #
  def sortable(name, column, _custom_icon)
    current_sort_key = params.dig(:q, :s)
    current_column, current_direction = current_sort_key&.split || [nil, "asc"]

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

  # == shade_for_value
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Color Helper
  #
  # @description
  #   Calculates a shade level based on value magnitude. Converts the number
  #   into a proportional color intensity mapped to {#SHADE_STEPS}.
  #
  # @param value [Numeric] The value to evaluate
  # @param max_value [Numeric] The upper limit for 100% intensity (default: 100_000)
  # @return [Integer] The shade level from SHADE_STEPS
  #
  # @example
  #   shade_for_value(50000, max_value: 100000)
  #   # => 500
  #
  def shade_for_value(value, max_value: 100_000)
    return 50 if value.to_f <= 0

    v = [value.to_f, max_value].min
    ratio = v / max_value
    index = (ratio * (SHADE_STEPS.size - 1)).round

    SHADE_STEPS[index]
  end

  # == Public Methods ========================================================

  # == valid_nonzero_number?
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Validation
  #
  # @description
  #   Validates that the provided value is present, numeric, and non-zero.
  #
  # @param value [Object] The value to check
  # @return [Boolean] True if valid and non-zero
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
  #   Resolves semantic CSS color classes based on the sign of a numeric value.
  #
  # @param numeric_value [Numeric] The value to evaluate
  # @return [String] CSS class name
  #
  def sign_color_class(numeric_value)
    return "text-danger-600" if numeric_value.negative?
    return "text-alert-600"  if numeric_value.zero?

    "text-body"
  end

  # == colored_base_classes
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category UI Helper
  #
  # @description
  #   Returns base CSS classes used by all colored helpers for consistent styling.
  #
  # @param additional_class [String] Extra classes to append
  # @return [String] Joined CSS classes
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
  # @category UI Helper
  #
  # @description
  #   Renders a currency value with semantic coloring based on its sign.
  #
  # @param value [Numeric] The value to display
  # @param additional_class [String] Extra CSS classes
  # @return [String] HTML span element
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
  # @category UI Helper
  #
  # @description
  #   Renders a numeric value with semantic coloring and single decimal precision.
  #
  # @param value [Numeric] The value to display
  # @param additional_class [String] Extra CSS classes
  # @return [String] HTML span element
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
  # @category UI Helper
  #
  # @description
  #   Renders a percentage value with semantic coloring and the % symbol.
  #
  # @param value [Numeric] The value to display
  # @param additional_class [String] Extra CSS classes
  # @return [String] HTML span element
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
  #   Formats a date and time into a readable string and wraps it in a styled
  #   HTML element with monospaced font.
  #
  # @param datetime [DateTime] The timestamp to format
  # @param formatter [Proc] Lambda to handle custom formatting
  # @return [String] HTML span element
  #
  # @example Default format
  #   formatted_timestamp(Time.now)
  #   # => "<span class='font-mono'>DD/MM/YYYY</span>"
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
  #   Displays a currency amount using a standard Brazilian pattern without sign coloring.
  #
  # @param value [Numeric] The value to format
  # @param additional_class [String] Extra CSS classes
  # @return [String] HTML span element
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
  #   Formats a number to a specific amount of decimal places for uniform alignment.
  #
  # @param number [Numeric] The raw value to be formatted
  # @param precision [Integer] Number of decimal places (default: 2)
  # @return [String] HTML span element
  #
  # @example 3 decimal places
  #   precision_format(1.2345, precision: 3)
  #   # => "<span class='font-mono'>1,235</span>"
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
#   Maps semantic color names to specific Tailwind CSS utility classes for info cards.
#
# @return [Hash<String, Hash>] The color mapping configuration
#
unless defined?(INFO_CARD_COLORS)
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
end

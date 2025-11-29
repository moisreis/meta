# === application_helper
#
# @author Moisés Reis
# @added 11/25/2025
# @package *Meta*
# @description This file contains utility methods that assist **Views** and other components
#              in presenting data consistently and managing global application logic.
#              The explanations are in the present simple tense.
# @category *Helper*
#
# Usage:: - *[What]* This code block stores small, reusable functions that simplify the HTML templates, such as formatting numbers or generating UI elements.
#         - *[How]* It defines methods that take data as input, process it (e.g., format a date, calculate a class name), and return the final output for the view.
#         - *[Why]* It keeps the **Views** clean by preventing repeated logic and ensuring a consistent user experience across the entire application.
#
module ApplicationHelper

  # == full_title
  #
  # @author Moisés Reis
  # @category *Read*
  #
  # Read:: This method constructs the full page title for the browser tab.
  #        It combines a specific page title with the base application name.
  #
  # Attributes:: - *page_title* @string - The specific title of the current page (e.g., "User Profile").
  #
  def full_title(page_title)

    # Explanation:: This defines the base name of the application, used if no specific
    #               page title is provided.
    base_title = "Financial Portfolio Manager"

    # Explanation:: This checks if the `page_title` argument is empty. If it is,
    #               it returns only the base title.
    if page_title.blank?
      base_title
    else

      # Explanation:: If a page title is provided, it combines the specific title
      #               with the base title, separated by a pipe character `|`.
      "#{page_title} | #{base_title}"
    end
  end

  # == currency_format
  #
  # @author Moisés Reis
  # @category *Read*
  #
  # Read:: This method formats numerical data into a standard Brazilian currency string (R$).
  #        It improves readability by adding the currency symbol, comma, and two decimal places.
  #
  # Attributes:: - *amount* @numeric - The number value to be formatted (e.g., 1234.56).
  #
  def currency_format(amount)

    # Explanation:: This uses the built-in Rails number formatting utility to convert
    #               the raw number into a currency string formatted for the Brazilian locale.
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
  # @category *Read*
  #
  # Read:: This method maps Rails flash message types (like `notice` or `alert`) to corresponding CSS classes.
  #        It ensures that success messages look green, error messages look red, and so on.
  #
  # Attributes:: - *flash_type* @symbol - The type of flash message (e.g., `:notice`, `:alert`, `:error`).
  #
  def flash_class_for(flash_type)
    # Explanation:: This converts the symbol type into a string key and uses a `case`
    #               statement to return the appropriate Bootstrap-compatible CSS class name.
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
      # Explanation:: This provides a default class for any message types that are not
      #               specifically mapped above.
      flash_type.to_s
    end
  end

  # == sortable
  #
  # @author Moisés Reis
  # @category *Read*
  #
  # Read:: This method generates an HTML link that makes a table column sortable using **Ransack** parameters.
  #        It automatically switches the sort direction (ascending/descending) and updates the visual icon.
  #
  # Attributes:: - *name* @string - The display name for the column header (e.g., "Fund Name").
  #             - *column* @symbol - The database column name to sort by (e.g., `:fund_name`).
  #             - *custom_icon* @string - The filename of the SVG icon to display next to the name.
  #
  def sortable(name, column, custom_icon)

    # Explanation:: This retrieves the current sort key from the web address parameters,
    #               specifically looking for the **Ransack** sort parameter, which is often under `params[:q][:s]`.
    current_sort_key = params.dig(
      :q,
      :s
    )

    # Explanation:: This separates the current sort key (e.g., "cnpj desc") into the column
    #               name (`current_column`) and the direction (`current_direction`), defaulting to "asc" if no sort is active.
    current_column, current_direction = current_sort_key&.split || [nil, "asc"]

    # Explanation:: This determines the next sort direction. If the user clicks the currently
    #               sorted column, the direction flips; otherwise, it defaults to ascending ("asc").
    direction =
      if current_column == column.to_s
        current_direction == "asc" ? "desc" : "asc"
      else
        "asc"
      end

    # Explanation:: This constructs the new **Ransack** sort string (e.g., "fund_name desc")
    #               that will be placed in the web address when the link is clicked.
    new_sort = "#{column} #{direction}"

    # Explanation:: This determines which arrow icon to display based on the current sort state:
    #               an upward arrow for ascending, a downward arrow for descending, or a default arrow if the column is not sorted.
    icon =
      if current_column != column.to_s
        "arrow-down"
      elsif current_direction == "asc"
        "arrow-up"
      else
        "arrow-down"
      end

    # Explanation:: This generates the final HTML link, merging the new sort parameter into the
    #               existing web address parameters and wrapping the custom icon, column name, and arrow icon inside it.
    link_to params.permit!.merge(q: (params[:q] || {}).merge(s: new_sort)) do
      content_tag(:div, class: "flex flex-row gap-1 items-center [&>svg]:size-3.5 [&>svg]:stroke-body") do
        safe_join([
                    name,
                    inline_svg_tag("icons/#{icon}.svg")
                  ])
      end
    end
  end

  # Explanation:: Defines a fixed list of numeric shade levels used to
  #               determine how strong the color intensity should be.
  #               Freezing prevents accidental modifications.
  SHADE_STEPS = [50, 100, 200, 300, 400, 500, 600, 700, 800, 900].freeze

  # == shade_for_value
  #
  # @author Moisés Reis
  # @category *Read*
  #
  # Read:: Calculates a shade level based on how large the value is.
  #        Converts the number into a proportional color intensity
  #        that becomes stronger with higher values.
  #
  def shade_for_value(value, max_value: 100_000)

    # Explanation:: Returns the lowest shade when the value is zero or
    #               negative to avoid unnecessary calculations.
    return 50 if value.to_f <= 0

    # Explanation:: Ensures the value does not exceed the allowed limit.
    #               This keeps the ratio calculation within safe bounds.
    v = [value.to_f, max_value].min

    # Explanation:: Converts the capped value into a 0–1 scale so it can
    #               be mapped proportionally to the shade list.
    ratio = v / max_value

    # Explanation:: Calculates which shade index best represents the ratio.
    #               Rounds to the nearest available shade step.
    index = (ratio * (SHADE_STEPS.size - 1)).round

    # Explanation:: Returns the chosen shade based on the computed index.
    #               This shade is later used to build the CSS class.
    SHADE_STEPS[index]
  end

  # == colored_currency
  #
  # @author Moisés Reis
  # @category *Read*
  #
  # Read:: Displays a currency amount with a background color that
  #        becomes darker for larger values. Helps users visually
  #        compare monetary figures at a glance.
  #
  def colored_currency(value, additional_class = "")

    # Explanation:: Returns a neutral placeholder when the value is blank or zero.
    #               Prevents meaningless values from being styled or displayed.
    return content_tag(:span, "N/A", class: "text-muted") unless value.present? && value.to_f != 0

    # Explanation:: Determines how intense the color should be for the value.
    #               Uses shade_for_value to pick the correct shade step.
    shade = shade_for_value(value)

    # Explanation:: Builds the HTML span showing the formatted currency and
    #               applies a class that encodes the chosen shade level.
    content_tag(
      :span,
      number_to_currency(value, unit: "R$ ", separator: ",", delimiter: "."),
      class: "shade font-mono px-3 py-0.5 min-h-9 max-h-12 flex items-center currency-shade-#{shade} #{additional_class}"
    )
  end

  # == colored_numerical
  #
  # @author Moisés Reis
  # @category *Read*
  #
  # Read:: Displays a numerical amount with a background color that
  #        becomes darker for larger values. Helps users visually
  #        compare numerical figures at a glance.
  #
  def colored_numerical(value, additional_class = "")

    # Explanation:: Returns a neutral placeholder when the value is blank or zero.
    #               Prevents meaningless values from being styled or displayed.
    return content_tag(:span, "N/A", class: "text-muted") unless value.present? && value.to_f != 0

    # Explanation:: Determines how intense the color should be for the value.
    #               Uses shade_for_value to pick the correct shade step.
    shade = shade_for_value(value)

    # Explanation:: Limits the precision of the numerical value
    value = number_with_precision(value, precision: 3)

    # Explanation:: Builds the HTML span showing the formatted numerical and
    #               applies a class that encodes the chosen shade level.
    content_tag(
      :span,
      value,
      class: "shade font-mono px-3 py-0.5 min-h-9 max-h-12 flex items-center numerical-shade-#{shade} #{additional_class}"
    )
  end

  # == colored_percentage
  #
  # @author Moisés Reis
  # @category *Read*
  #
  # Read:: Displays a percentage amount with a background color that
  #        becomes darker for larger values. Helps users visually
  #        compare percentage figures at a glance.
  #
  def colored_percentage(value, additional_class = "")

    # Explanation:: Returns a neutral placeholder when the value is blank or zero.
    #               Prevents meaningless values from being styled or displayed.
    return content_tag(:span, "N/A", class: "text-muted") unless value.present? && value.to_f != 0

    # Explanation:: Determines how intense the color should be for the value.
    #               Uses shade_for_value to pick the correct shade step.
    shade = shade_for_value(value, max_value: 100)

    # Explanation:: Limits the precision of the numerical value
    value = number_with_precision(value, precision: 3)

    # Explanation:: Builds the HTML span showing the formatted percentage and
    #               applies a class that encodes the chosen shade level.
    content_tag(
      :span,
      "#{value}%",
      class: "shade font-mono px-3 py-0.5 min-h-9 max-h-12 flex items-center percentage-shade-#{shade} #{additional_class}"
    )
  end

  # == formatted_timestamp
  #
  # @author Moisés Reis
  # @category *Read*
  #
  # Read:: Formats a date and time into a readable string and wraps it
  #        in a styled HTML element. Presents timestamps consistently
  #        across the interface for better readability.
  #
  def formatted_timestamp(datetime, formatter: ->(t) { t.strftime("%d/%m/%Y") })

    # Explanation:: Returns a placeholder when the datetime value is missing.
    #               Prevents errors and keeps the visual layout stable.
    return content_tag(:span, "N/A", class: "font-mono text-muted") unless datetime.present?

    # Explanation:: Uses the formatter to turn the datetime into a formatted
    #               string. Allows injecting alternative formatting logic.
    formatted = formatter.call(datetime)

    # Explanation:: Builds a span containing the formatted date string and
    #               applies a consistent monospaced style for alignment.
    content_tag(:span, formatted, class: "font-mono")
  end
end
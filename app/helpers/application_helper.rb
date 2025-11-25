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
        "keyboard_arrow_down"
      elsif current_direction == "asc"
        "keyboard_arrow_up"
      else
        "keyboard_arrow_down"
      end

    # Explanation:: This generates the final HTML link, merging the new sort parameter into the
    #               existing web address parameters and wrapping the custom icon, column name, and arrow icon inside it.
    link_to params.permit!.merge(q: (params[:q] || {}).merge(s: new_sort)) do
      content_tag(:div, class: "flex flex-row gap-1 items-center [&>svg]:size-4 [&>svg]:fill-primary-50") do
        safe_join([
                    inline_svg_tag("icons/#{custom_icon}.svg"),
                    name,
                    inline_svg_tag("icons/#{icon}.svg")
                  ])
      end
    end
  end
end
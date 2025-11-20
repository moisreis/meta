# === application_helper
#
# @author Moisés Reis
# @added 11/20/2025
# @package *Meta*
# @description Defines shared view helper methods used across the application.
#              Keeps UI-related logic inside **ApplicationHelper** so that
#              controllers and models remain focused on their own responsibilities.
#              Ensures consistent rendering behavior for sortable table headers.
# @category *Helper*
#
# Usage:: - *[what]* This module stores helper methods that support views.
#         - *[how]* It builds UI elements, processes parameters, and produces
#                   reusable markup through **ActionView** helpers.
#         - *[why]* It centralizes view logic to improve readability, maintainability,
#                   and separation of concerns within the application.
#
module ApplicationHelper

  # [Helper] Builds a clickable sortable column header.
  #          Computes sort direction, updates query parameters, and renders icons.
  def sortable(name, column, custom_icon)
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
        "keyboard_arrow_down"
      elsif current_direction == "asc"
        "keyboard_arrow_up"
      else
        "keyboard_arrow_down"
      end

    link_to params.permit!.merge(q: (params[:q] || {}).merge(s: new_sort)) do
      content_tag(:div, class: "flex flex-row gap-1 items-center [&>svg]:size-4") do
        safe_join([
                    inline_svg_tag("icons/#{custom_icon}.svg"),
                    name,
                    inline_svg_tag("icons/#{icon}.svg")
                  ])
      end
    end
  end
end
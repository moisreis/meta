# === nav_helper
#
# @author Moisés Reis
# @added 11/20/2025
# @package *Meta*
# @category *Model*
#
# @description Provides navigation helpers that build CRUD-oriented
#              interface elements. Generates buttons and sections that
#              guide the user through the **controller** actions associated
#              with the given model. Produces markup in a compact and
#              reusable shape, and keeps the UI consistent across resources.
#
# Usage:: - *[what]* Generates a vertical navigation block for CRUD screens
#         - *[how]* Fetches naming information from the model, produces
#                   structured items, merges icons, and renders buttons
#                   using view helpers
#         - *[why]* Keeps navigation consistent across resources and
#                   reduces duplication in **views** and **controllers**
#
# Attributes:: - *model_class* @class - the **ActiveRecord** model that determines
#                                       naming, paths, and count metadata
#
module NavHelper

  # [Method] Builds a CRUD navigation block
  #          for a given model in a clear and reusable way.
  def crud_nav_for(model_class, singular: nil, plural: nil, icons: {})
    singular ||= model_class.model_name.human
    plural ||= model_class.model_name.human(count: 2)
    resources = model_class.model_name.route_key
    count = model_class.count

    default_icons = {
      index: "wallet.svg",
      new: "add.svg",
      reports: "article.svg"
    }

    icon_set = default_icons.merge(icons.symbolize_keys)

    items = [
      {
        icon: icon_set[:index],
        text: "#{plural} <b>(#{count})</b>",
        # [Correção] Prefixa o nome do controller com '/' para forçar o namespace global
        # e evitar que Devise ou outros namespaces o prefixem (ex: "devise/portfolios").
        path: url_for(controller: "/#{resources}", action: :index)
      },
      {
        icon: icon_set[:new],
        text: "Adicionar",
        # [Correção] Aplica a mesma regra para a ação 'new'.
        path: url_for(controller: "/#{resources}", action: :new)
      },
      {
        icon: icon_set[:reports],
        text: "Relatórios",
        # [Correção] Aplica a mesma regra para a rota de relatórios.
        path: url_for(controller: "/#{resources}", action: :index, reports: true)
      }
    ]

    content_tag :div, class: "flex flex-col gap-1.5 items-start justify-start" do
      safe_join([
                  content_tag(:h3, plural, class: "text-2xs font-semibold uppercase text-muted"),
                  *items.map { |item| crud_nav_button(item) }
                ])
    end
  end

  # [Method] Builds a single navigation button
  #          and styles it based on the active route.
  def crud_nav_button(item)
    active = current_page?(item[:path])

    classes = [
      "button",
      "button-small",
      ("button-primary" if active),
      ("button-ghost" unless active)
    ].compact.join(" ")

    link_to item[:path], class: classes do
      inline_svg_tag("icons/#{item[:icon]}", class: "size-4") +
        content_tag(:span, item[:text].html_safe, class: "relative")
    end
  end
end
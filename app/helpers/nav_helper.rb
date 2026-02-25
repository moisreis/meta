module NavHelper

  def crud_nav_for(model_class, singular: nil, plural: nil, icons: {}, index_path: nil, new_path: nil)
    singular ||= model_class.model_name.human
    plural   ||= model_class.model_name.human(count: 2)

    resources = model_class.model_name.route_key

    default_icons = { index: "wallet.svg", new: "plus.svg" }
    icon_set = default_icons.merge(icons.symbolize_keys)

    items = [
      {
        icon: icon_set[:index],
        text: "Ver todos",
        path: index_path || url_for(controller: "/#{resources}", action: :index)
      },
      {
        icon: icon_set[:new],
        text: "Adicionar novo",
        path: new_path || url_for(controller: "/#{resources}", action: :new)
      }
    ]

    nav_id = "nav-#{resources}"

    content_tag :div, class: "flex flex-col gap-1.5 w-full" do
      safe_join([
                  content_tag(:div, class: "flex flex-row justify-center items-center w-full") do
                    safe_join([
                                content_tag(:span, plural,
                                            class: "px-3 text-2xs font-mono font-semibold uppercase text-muted"),
                                content_tag(:div, nil,
                                            class: "h-[2px] bg-neutral-200 w-full")
                              ])
                  end,
                  content_tag(:div, id: nav_id,
                              class: "flex flex-col gap-1 px-1.5 w-full") do
                    safe_join(items.map { |item| crud_nav_button(item) })
                  end
                ])
    end
  end

  def crud_nav_button(item)
    active = current_page?(item[:path])

    classes = [
      "relative",
      "button",
      "button-small",
      "w-full",
      "flex flex-row justify-start",
      ("button-ghost" unless active),
      ("button-honeysuckle" if active)
    ].compact.join(" ")

    link_to item[:path], class: classes do
      safe_join(
        [
          inline_svg_tag("icons/#{item[:icon]}", class: "w-4 h-4"),
          content_tag(:span, item[:text], class: "text-sm font-medium")
        ]
      )
    end
  end
end
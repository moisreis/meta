# app/presenters/nav_presenter.rb
# frozen_string_literal: true

# Renders structured sidebar and navigation menu sections.
#
# This presenter encapsulates reusable navigation rendering behavior,
# including:
# - section headers
# - grouped navigation items
# - active-state navigation buttons
# - icon integration
#
# @author Moisés Reis

class NavPresenter

  # ==========================================================================
  # INITIALIZATION
  # ==========================================================================

  # Initializes the presenter with the current Rails view context.
  #
  # @param view_context [ActionView::Base] Rails view context instance.
  def initialize(view_context)
    @view = view_context
  end

  # ==========================================================================
  # PUBLIC METHODS
  # ==========================================================================

  # Renders a complete navigation section.
  #
  # The rendered structure includes:
  # - section header
  # - navigation container
  # - navigation buttons
  #
  # @param label [String] Section title displayed above navigation items.
  # @param nav_id [String] DOM identifier applied to the navigation container.
  # @param items [Array<Hash>] Navigation item definitions.
  #
  # @option items [String] :path URL path used for navigation.
  # @option items [String] :icon SVG icon filename rendered for the item.
  # @option items [String] :text Display text rendered for the item.
  #
  # @return [ActiveSupport::SafeBuffer] Rendered navigation section HTML.
  def render(label:, nav_id:, items:)
    @view.content_tag(
      :div,
      class: "flex flex-col justify-start items-start gap-1.5 w-full"
    ) do
      @view.safe_join([
        section_header(label),
        items_container(nav_id, items)
      ])
    end
  end

  private

  # ==========================================================================
  # PRIVATE METHODS
  # ==========================================================================

  # Renders the navigation section header.
  #
  # @param label [String] Header label displayed above navigation items.
  # @return [ActiveSupport::SafeBuffer] Rendered section header HTML.
  def section_header(label)
    @view.content_tag(
      :div,
      class: "flex flex-row justify-start items-center w-full"
    ) do
      @view.content_tag(
        :span,
        label,
        class: "px-3 text-3xs font-mono tracking-widest font-semibold uppercase text-neutral-50 opacity-40"
      )
    end
  end

  # Renders the navigation item container.
  #
  # @param nav_id [String] DOM identifier applied to the container element.
  # @param items [Array<Hash>] Navigation item definitions.
  # @return [ActiveSupport::SafeBuffer] Rendered navigation items container.
  def items_container(nav_id, items)
    @view.content_tag(
      :div,
      id: nav_id,
      class: "flex flex-col gap-1 px-1.5 w-full"
    ) do
      @view.safe_join(items.map { |item| nav_button(item) })
    end
  end

  # Renders an individual navigation button.
  #
  # Active navigation items receive dedicated styling based on the
  # current request path.
  #
  # @param item [Hash] Navigation item definition.
  #
  # @option item [String] :path URL path used for navigation.
  # @option item [String] :icon SVG icon filename rendered for the item.
  # @option item [String] :text Display text rendered for the item.
  #
  # @return [ActiveSupport::SafeBuffer] Rendered navigation button HTML.
  def nav_button(item)
    active = @view.current_page?(item[:path])

    classes = [
      "relative button button-small w-full flex flex-row justify-start",
      active ? "button-sidebar--active" : "button-sidebar"
    ].join(" ")

    @view.link_to(item[:path], class: classes) do
      @view.safe_join([
        @view.inline_svg_tag(
          "icons/#{item[:icon]}",
          class: "w-4 h-4"
        ),
        @view.content_tag(
          :span,
          item[:text],
          class: "text-sm font-medium"
        )
      ])
    end
  end
end

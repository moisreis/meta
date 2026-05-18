# app/components/ui/sidebar_component.rb
# frozen_string_literal: true

# Generic slide-over sidebar shell. Wraps any form content with a consistent
# header, close behaviour, and overlay — driven by SidebarController (Stimulus).
#
# The close/cancel buttons *inside* the yielded content should carry:
#   data-action="click->sidebar#close"
# They will bubble up to this component's controller automatically.
#
# @example
#   <%= render Ui::SidebarComponent.new(name: "application", title: "Nova Aplicação") do %>
#     <%= form_with(model: @new_application) do |f| %>
#       ...
#       <button data-action="click->sidebar#close">Cancelar</button>
#     <% end %>
#   <% end %>

class Layout::DrawerComponent < ApplicationComponent
  # @param name  [String] Unique key matching the sidebar-opener's name value.
  # @param title [String] Text shown in the panel header.
  def initialize(name:, title:)
    @name  = name
    @title = title
  end
end
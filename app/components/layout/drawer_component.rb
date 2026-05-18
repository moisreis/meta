# frozen_string_literal: true

# Renders a side slide-over drawer panel container component that manages
# its open/close presentation state via client-side Stimulus behaviors.
#
# @author Moisés Reis
class Layout::DrawerComponent < ApplicationComponent

  # =============================================================
  # INITIALIZATION
  # =============================================================

  # Initializes the drawer component with targeting and header display metrics.
  #
  # @param name [String] Unique identifying name for the drawer instance, utilized by the Stimulus target listener.
  # @param title [String] Headline text rendered within the top navigation block of the drawer container.
  # @return [Layout::DrawerComponent]
  def initialize(name:, title:)
    @name  = name
    @title = title
  end
end
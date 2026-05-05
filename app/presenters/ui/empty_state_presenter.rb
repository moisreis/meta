# frozen_string_literal: true

# app/presenters/ui/empty_state_presenter.rb
#
# Ui namespace containing reusable presenter components for consistent UI rendering.
#
# Standardized empty-state renderer.
#
# @author Moisés Reis
module Ui
  # =============================================================
  #                 Ui::EmptyStatePresenter
  # =============================================================
  #
  # Provides a standardized representation for empty or missing values
  # across UI components.
  #
  class EmptyStatePresenter < BasePresenter

    # =============================================================
    #                 1. CONSTANTS & CONFIGURATION
    # =============================================================

    EMPTY_TEXT = "-".freeze

    # =============================================================
    #                        2a. RENDER
    # =============================================================

    # Renders a standardized empty-state element.
    #
    # @param text [String] The text to display. Defaults to EMPTY_TEXT.
    # @return [ActiveSupport::SafeBuffer] HTML span element with muted styling.
    def render(text = EMPTY_TEXT)
      h.content_tag(:span, text, class: "text-muted")
    end
  end
end

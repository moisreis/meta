# frozen_string_literal: true

# Provides UI presentation helpers and reusable rendering abstractions.
#
# This namespace groups presenter objects responsible for encapsulating
# reusable view rendering logic and presentation-specific formatting behavior.
#
# @author Moisés Reis

module Ui

  # Renders standardized empty-state placeholder content.
  #
  # This presenter provides a centralized visual representation for
  # missing, blank, or unavailable values throughout the UI layer.
  class EmptyStatePresenter < BasePresenter

    # ==========================================================================
    # CONSTANTS
    # ==========================================================================

    # Default placeholder text rendered for empty values.
    #
    # @return [String] Default empty-state display content.
    EMPTY_TEXT = "-".freeze

    # ==========================================================================
    # PUBLIC METHODS
    # ==========================================================================

    # Renders empty-state placeholder content.
    #
    # @param text [String] Placeholder text rendered for empty values.
    # @return [ActiveSupport::SafeBuffer] Rendered HTML span element.
    def render(text = EMPTY_TEXT)
      h.content_tag(
        :span,
        text,
        class: "text-muted"
      )
    end
  end
end

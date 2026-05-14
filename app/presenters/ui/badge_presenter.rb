# frozen_string_literal: true

# Provides UI presentation helpers and reusable rendering abstractions.
#
# This namespace groups presenter objects responsible for encapsulating
# reusable view rendering logic and presentation-specific formatting behavior.
#
# @author Moisés Reis

module Ui

  # Renders styled badge components for textual content.
  #
  # This presenter generates deterministic or explicitly selected badge
  # variants and delegates blank-state rendering to {EmptyStatePresenter}.
  class BadgePresenter < BasePresenter

    # ==========================================================================
    # CONSTANTS
    # ==========================================================================

    # Available badge style variants.
    #
    # @return [Array<String>] Supported badge type identifiers.
    TYPES = %w[
      inchworm
      indigo
      teal
      primary
      honeysuckle
    ].freeze

    # ==========================================================================
    # INITIALIZATION
    # ==========================================================================

    # Initializes the presenter.
    #
    # @param view_context [ActionView::Base] Rails view context instance.
    def initialize(view_context)
      super

      @empty = EmptyStatePresenter.new(view_context)
    end

    # ==========================================================================
    # PUBLIC METHODS
    # ==========================================================================

    # Renders a styled badge component.
    #
    # When no explicit type is provided, a deterministic badge variant
    # is selected based on the content hash.
    #
    # @param content [String, #to_s, nil] Content rendered inside the badge.
    # @param type [String, nil] Explicit badge type override.
    # @return [ActiveSupport::SafeBuffer] Rendered HTML badge element.
    def render(content, type: nil)
      return @empty.render if content.blank?

      selected = type || deterministic_type(content)

      h.content_tag(
        :span,
        content,
        class: "badge badge-#{selected}"
      )
    end

    private

    # ==========================================================================
    # PRIVATE METHODS
    # ==========================================================================

    # Selects a deterministic badge type based on content hashing.
    #
    # This ensures visually stable badge coloring for identical content
    # across requests and render cycles.
    #
    # @param content [String, #to_s] Content used for deterministic hashing.
    # @return [String] Deterministically selected badge type.
    def deterministic_type(content)
      TYPES[Zlib.crc32(content.to_s) % TYPES.size]
    end
  end
end

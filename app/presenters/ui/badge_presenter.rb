# frozen_string_literal: true

# app/presenters/ui/badge_presenter.rb
#
# Ui namespace containing presenters responsible for standardized UI rendering.
#
# Styled badge renderer with deterministic type selection.
#
# @author Moisés Reis
module Ui
  # =============================================================
  #                 Ui::BadgePresenter
  # =============================================================
  #
  # Provides consistent badge rendering with optional explicit styling
  # or deterministic type assignment based on content hashing.
  #
  class BadgePresenter < BasePresenter

    # =============================================================
    #                 1. CONSTANTS & CONFIGURATION
    # =============================================================

    TYPES = %w[inchworm indigo teal primary honeysuckle].freeze

    # =============================================================
    #                      2. INITIALIZATION
    # =============================================================

    # @param view_context [ActionView::Base] Rails view context providing helper methods.
    def initialize(view_context)
      super
      @empty = EmptyStatePresenter.new(view_context)
    end

    # =============================================================
    #                        3a. RENDER
    # =============================================================

    # Renders a styled badge element.
    #
    # @param content [String, nil] Text displayed inside the badge.
    # @param type [String, nil] Optional explicit badge type override.
    # @return [ActiveSupport::SafeBuffer] HTML span element or empty-state fallback.
    def render(content, type: nil)
      return @empty.render if content.blank?

      selected = type || deterministic_type(content)
      h.content_tag(:span, content, class: "badge badge-#{selected}")
    end

    private

    # =============================================================
    #               4a. DETERMINISTIC TYPE SELECTION
    # =============================================================

    # Selects a deterministic badge type based on CRC32 hashing.
    #
    # Ensures stable visual distribution of badge colors for identical inputs.
    #
    # @param content [String] Input used to derive deterministic type.
    # @return [String] Selected badge type.
    def deterministic_type(content)
      TYPES[Zlib.crc32(content.to_s) % TYPES.size]
    end
  end
end

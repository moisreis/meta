# frozen_string_literal: true

# Component responsible for rendering a configurable UI card with status-based
# styling, optional header elements, and badge support.
#
# This component enforces a strict set of allowed status values to ensure
# consistent visual semantics across the application.
#
# @author Moisés Reis

class Blocks::CardComponent < ApplicationComponent

  # ==========================================================================
  # CONSTANTS
  # ==========================================================================

  # Allowed status keys for visual semantic mapping.
  STATUSES = %i[
    success danger alert primary teal honeysuckle indigo secondary default
  ].freeze

  # Background color mapping for the status dot indicator.
  DOT_COLORS = {
    success:     "bg-success-500",
    danger:      "bg-danger-500",
    alert:       "bg-alert-500",
    primary:     "bg-primary-500",
    teal:        "bg-teal-500",
    honeysuckle: "bg-honeysuckle-500",
    indigo:      "bg-indigo-500",
    secondary:   "bg-secondary-500",
    default:     "bg-neutral-300"
  }.freeze

  # ==========================================================================
  # INITIALIZATION
  # ==========================================================================

  # @param status [Symbol, String] The status key for the card (must be in STATUSES).
  # @param title [String, nil] The title displayed in the card header.
  # @param header_icon [String, nil] Lucide icon name for the header.
  # @param badge_text [String, nil] Text for the optional status badge.
  # @param badge_icon [String, nil] Lucide icon name for the optional badge.
  # @raise [ArgumentError] If the provided status is not permitted.
  def initialize(
    status: :default,
    title: nil,
    header_icon: nil,
    badge_text: nil,
    badge_icon: nil
  )
    @status       = normalize_status(status)
    @title        = title
    @header_icon  = header_icon
    @badge_text   = badge_text
    @badge_icon   = badge_icon
  end

  # ==========================================================================
  # PRESENTATION HELPERS
  # ==========================================================================

  # Returns the CSS class for the status dot.
  # @return [String]
  def dot_color
    DOT_COLORS.fetch(status)
  end

  # @return [Boolean]
  def show_badge?
    badge_text.present?
  end

  # @return [Boolean]
  def show_badge_icon?
    badge_icon.present?
  end

  # ==========================================================================
  # PRIVATE
  # ==========================================================================

  private

  attr_reader :status, :title, :header_icon, :badge_text, :badge_icon

  # Normalizes input and validates against allowed statuses.
  #
  # @param value [Object] The input status.
  # @return [Symbol]
  # @raise [ArgumentError] If status is invalid.
  def normalize_status(value)
    sym = value.to_sym
    return sym if STATUSES.include?(sym)

    raise ArgumentError, "Invalid status: #{value}. Allowed: #{STATUSES.join(', ')}"
  end
end

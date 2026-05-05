# frozen_string_literal: true

class Blocks::CardComponent < ApplicationComponent
  STATUSES = %i[
    success danger alert primary teal honeysuckle indigo secondary default
  ].freeze

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

  def dot_color
    DOT_COLORS.fetch(status)
  end

  def show_badge?
    badge_text.present?
  end

  def show_badge_icon?
    badge_icon.present?
  end

  private

  attr_reader :status, :title, :header_icon, :badge_text, :badge_icon

  def normalize_status(value)
    sym = value.to_sym
    return sym if STATUSES.include?(sym)

    raise ArgumentError, "Invalid status: #{value}. Allowed: #{STATUSES.join(', ')}"
  end
end
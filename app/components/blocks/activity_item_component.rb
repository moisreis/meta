# frozen_string_literal: true

# app/components/blocks/activity_item_component.rb
#
# Component responsible for rendering a single activity item with
# contextual color coding, icon selection, and formatted metadata.
#
# This component is used inside activity feeds and grouped dashboards
# to standardize presentation of state-driven events.
#
# @author  Moisés Reis

class Blocks::ActivityItemComponent < ApplicationComponent

  # == Constants ==============================================================

  # -- Color Styling ----------------------------------------------------------

  # Style mapping for various activity states.
  COLORS = {
    success:     { bg: "bg-success-50",     stroke: "stroke-success-500",     text: "text-success-600"     },
    danger:      { bg: "bg-danger-50",      stroke: "stroke-danger-500",      text: "text-danger-600"      },
    alert:       { bg: "bg-alert-50",       stroke: "stroke-alert-500",       text: "text-alert-600"       },
    primary:     { bg: "bg-primary-50",     stroke: "stroke-primary-500",     text: "text-primary-600"     },
    teal:        { bg: "bg-teal-50",        stroke: "stroke-teal-500",        text: "text-teal-600"        },
    honeysuckle: { bg: "bg-honeysuckle-50", stroke: "stroke-honeysuckle-500", text: "text-honeysuckle-600" },
    indigo:      { bg: "bg-indigo-50",      stroke: "stroke-indigo-500",      text: "text-indigo-600"      },
    secondary:   { bg: "bg-secondary-50",   stroke: "stroke-secondary-500",   text: "text-secondary-600"   },
    default:     { bg: "bg-neutral-100",    stroke: "stroke-neutral-400",     text: "text-neutral-700"     }
  }.freeze

  # Fallback styling if an invalid color key is provided.
  FALLBACK_COLOR = COLORS[:default]


  # == Class Methods ==========================================================

  # Initializes the activity item component with necessary display metrics and context.
  #
  # @param title [String] The main descriptive text for the activity.
  # @param value [String] The primary metric or value associated with the event.
  # @param sub [String] Secondary information or label.
  # @param date [DateTime, Time, nil] The timestamp of the event.
  # @param color [Symbol] The theme key from the COLORS constant.
  # @return [Blocks::ActivityItemComponent]
  def initialize(title:, value:, sub:, date: nil, color: :default)
    @title = title
    @value = value
    @sub   = sub
    @date  = date
    @color = color.to_sym
  end


  # == Instance Methods =======================================================

  # Returns the Tailwind class mapping for the current color theme.
  #
  # @return [Hash{Symbol => String}] Map of Tailwind classes.
  def color_classes
    COLORS.fetch(@color, FALLBACK_COLOR)
  end

  # -- Asset Helpers ----------------------------------------------------------

  # Determines the Lucide icon based on the activity state.
  #
  # @return [String] The name of the icon asset to render.
  def icon_name
    @color == :success ? "arrow-up-right" : "arrow-down-left"
  end

  # -- Formatting -------------------------------------------------------------

  # Formats the localized date using the shared application timestamp helper.
  #
  # @return [String, nil] The formatted date string, or nil if no date is present.
  def formatted_date
    formatted_timestamp(@date)
  end

end
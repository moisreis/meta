# frozen_string_literal: true

# Renders a form-backed date/text field with optional icon,
# contextual description, accessibility attributes, and
# validation-aware styling.
#
# Supports:
# - date_field/text_field/custom field types
# - compact sizing
# - half-width layout
# - disabled states
# - inline validation messaging
# - datepicker stimulus controller
#
# @author Moisés Reis

class Forms::DateFieldComponent < ApplicationComponent

  # ==========================================================================
  # CONSTANTS
  # ==========================================================================

  LABEL_CLASSES = %w[
    flex items-center gap-1.5 text-muted text-2xs font-mono uppercase
    tracking-widest leading-none font-medium select-none
    group-data-[disabled=true]:pointer-events-none
    group-data-[disabled=true]:opacity-50
    peer-disabled:cursor-not-allowed
    peer-disabled:opacity-50
  ].join(" ").freeze

  INPUT_CLASSES = %w[
    placeholder:text-muted
    bg-input
    border
    border-border
    pr-6
    h-9
    w-full
    min-w-0
    rounded-base
    px-3
    py-1
    text-sm
    transition-[color,box-shadow]
    disabled:pointer-events-none
    disabled:cursor-not-allowed
    disabled:opacity-50
    aria-invalid:ring-danger-600/20
    aria-invalid:border-danger
  ].join(" ").freeze

  INPUT_HOVER_CLASSES = %w[
    hover:bg-table-hover
  ].join(" ").freeze

  INPUT_FOCUS_CLASSES = %w[
    focus-visible:border-border
    focus-visible:ring-1
    focus-visible:ring-primary-600/20
    focus-visible:outline-primary-600
    focus-visible:outline-1
    focus-visible:outline-offset-2
  ].join(" ").freeze

  DESC_BASE_CLASSES = %w[
    flex items-center gap-1.5 text-xs text-muted leading-none
    font-normal select-none
    group-data-[disabled=true]:pointer-events-none
    group-data-[disabled=true]:opacity-50
    peer-disabled:cursor-not-allowed
    peer-disabled:opacity-50
  ].join(" ").freeze

  DESC_ERROR_CLASSES = %w[
    !text-danger-600 !bg-danger-50 p-1.5 px-3
    border border-danger-100 rounded-base w-fit
  ].join(" ").freeze

  # ==========================================================================
  # INITIALIZATION
  # ==========================================================================

  def initialize(
    f:,
    name:,
    label: nil,
    desc: nil,
    placeholder: "Escolha uma data",
    field_type: :date_field,
    value: nil,
    data: {},
    icon_name: nil,
    is_inactive: false,
    is_half_width: false,
    is_small: false
  )
    @f              = f
    @name           = name
    @label          = label
    @desc           = desc
    @placeholder    = placeholder
    @field_type     = field_type
    @value          = value
    @data           = data
    @icon_name      = icon_name
    @is_inactive    = is_inactive
    @is_half_width  = is_half_width
    @is_small       = is_small
  end

  # ==========================================================================
  # ERROR HANDLING
  # ==========================================================================

  def has_error?
    @f.object.respond_to?(:errors) &&
      @f.object.errors[@name].present?
  end

  def error_message
    return unless has_error?

    @f.object.errors.full_messages_for(@name).first
  end

  # ==========================================================================
  # STYLE HELPERS
  # ==========================================================================

  def wrapper_width_class
    "!w-1/2" if @is_half_width
  end

  def input_classes
    [
      INPUT_CLASSES,
      INPUT_HOVER_CLASSES,
      INPUT_FOCUS_CLASSES,
      (@is_small ? "!h-fit !w-fit !px-2.5 !py-0.75" : nil)
    ].compact.join(" ")
  end

  def desc_classes
    has_error? ? "#{DESC_BASE_CLASSES} #{DESC_ERROR_CLASSES}" : DESC_BASE_CLASSES
  end

  def aria_describedby
    "#{@name}-desc" if @desc.present? || has_error?
  end
end
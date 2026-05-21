# frozen_string_literal: true

# Renders a form-backed date/text field with optional icon,
# contextual description, accessibility attributes, and
# validation-aware styling.
#
# @author Moisés Reis

class Forms::DateFieldComponent < ApplicationComponent
  include FormStyles

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
    @f             = f
    @name          = name
    @label         = label
    @desc          = desc
    @placeholder   = placeholder
    @field_type    = field_type
    @value         = value
    @data          = data
    @icon_name     = icon_name
    @is_inactive   = is_inactive
    @is_half_width = is_half_width
    @is_small      = is_small
  end

  # ==========================================================================
  # ERROR HANDLING
  # ==========================================================================

  def has_error?
    @f.object.respond_to?(:errors) && @f.object.errors[@name].present?
  end

  def error_message
    return unless has_error?
    @f.object.errors.full_messages_for(@name).first
  end

  # ==========================================================================
  # STYLE HELPERS
  # ==========================================================================

  def input_classes
    [
      INPUT_BASE_CLASSES,
      INPUT_HOVER_CLASSES,
      INPUT_FOCUS_CLASSES,
      (INPUT_SMALL_CLASSES if @is_small)
    ].compact.join(" ")
  end
end
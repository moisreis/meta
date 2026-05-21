# frozen_string_literal: true

# Component responsible for rendering configurable form input fields with
# validation-aware styling, masking support, and accessibility attributes.
#
# @author Moisés Reis

class Forms::InputFieldComponent < ApplicationComponent
  include FormStyles

  def initialize(
    f:,
    name:,
    label: nil,
    field_type: :text_field,
    placeholder: nil,
    desc: nil,
    icon_name: nil,
    is_inactive: nil,
    is_half_width: false,
    is_small: false,
    currency_mask: false,
    cnpj_mask: false,
    bank_account_mask: false,
    step: nil,
    inputmode: nil
  )
    @f                 = f
    @name              = name
    @label             = label
    @field_type        = field_type
    @placeholder       = placeholder
    @desc              = desc
    @icon_name         = icon_name
    @is_inactive       = is_inactive
    @is_half_width     = is_half_width
    @is_small          = is_small
    @currency_mask     = currency_mask
    @cnpj_mask         = cnpj_mask
    @bank_account_mask = bank_account_mask
    @step              = step
    @inputmode         = inputmode
  end

  # ==========================================================================
  # ERROR HANDLING
  # ==========================================================================

  def has_error?
    @f.object.respond_to?(:errors) && @f.object.errors[@name].present?
  end

  def error_message
    return unless has_error?
    @f.object.errors[@name].first
  end

  # ==========================================================================
  # STYLE RESOLUTION
  # ==========================================================================

  def full_input_classes
    [
      INPUT_BASE_CLASSES,
      INPUT_HOVER_CLASSES,
      INPUT_FOCUS_CLASSES,
      (INPUT_ERROR_CLASSES if has_error?),
      (INPUT_MONO_CLASSES  if mono_font_required?),
      (INPUT_SMALL_CLASSES if @is_small)
    ].compact.join(" ")
  end

  private

  def mono_font_required?
    @field_type == :number_field || @currency_mask || @cnpj_mask || @bank_account_mask
  end
end
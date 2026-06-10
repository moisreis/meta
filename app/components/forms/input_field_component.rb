# frozen_string_literal: true

# app/components/forms/input_field_component.rb
#
# Component responsible for rendering configurable form input fields with
# validation-aware styling, masking support, and accessibility attributes.
#
# @author  Moisés Reis

class Forms::InputFieldComponent < ApplicationComponent

  # == Concerns ===============================================================

  include FormStyles


  # == Class Methods ==========================================================

  # Initializes the input field component with explicit layout and masking options.
  #
  # @param f [ActionView::Helpers::FormBuilder] The ActiveService or ActiveRecord form builder instance.
  # @param name [Symbol, String] The attribute name mapped to the database record or form param.
  # @param label [String, nil] The title text displayed in the label element.
  # @param field_type [Symbol] ActionView form wrapper method type (e.g., :text_field, :number_field).
  # @param placeholder [String, nil] Placeholder hint string for empty states.
  # @param desc [String, nil] Supporting description or help text.
  # @param icon_name [String, nil] Lucide icon name for optional inner structural element.
  # @param is_inactive [Boolean, nil] Toggles disabled flag state on form boundaries.
  # @param is_half_width [Boolean] Restricts component container layout space on desktop layouts.
  # @param is_small [Boolean] Applies dense structural down-sizing attributes.
  # @param currency_mask [Boolean] Triggers monetary formatting behavioral masks.
  # @param cnpj_mask [Boolean] Triggers Brazilian corporate taxpayer identifier masking.
  # @param bank_account_mask [Boolean] Triggers specific account structure identifier masking.
  # @param step [String, Numeric, nil] HTML value interval mapping constraint for digital inputs.
  # @param inputmode [String, nil] Hints to the engine about virtual hardware optimization schemas.
  # @return [Forms::InputFieldComponent]
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


  # == Instance Methods =======================================================

  # -- Error Handling ---------------------------------------------------------

  # Evaluates whether the underlying record context contains active validation errors.
  #
  # @return [Boolean] True if database backing object has errors assigned to this field name.
  def has_error?
    @f.object.respond_to?(:errors) && @f.object.errors[@name].present?
  end

  # Extracts the first context-aware validation message if an error state exists.
  #
  # @return [String, nil] The structural validation error message, or nil if valid.
  def error_message
    return unless has_error?
    @f.object.errors[@name].first
  end

  # -- Style Resolution -------------------------------------------------------

  # Compiles the final collection of styling utilities applied to the markup input node.
  #
  # @return [String] Concatenated string containing core structural, interactive, 
  # and variant utility classes.
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


  # == Private Methods ========================================================

  # -- Typography Rules -------------------------------------------------------

  # Evaluates whether the underlying type constraints necessitate monospace rendering parameters.
  #
  # @return [Boolean] True if character alignments require proportional sizing overrides.
  def mono_font_required?
    @field_type == :number_field || @currency_mask || @cnpj_mask || @bank_account_mask
  end

end
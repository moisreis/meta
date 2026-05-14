# frozen_string_literal: true

# Component responsible for rendering configurable form input fields with
# validation-aware styling, masking support, and accessibility attributes.
#
# This component standardizes input behavior across form elements, including
# error states, sizing variants, and input formatting modes.
#
# @author Moisés Reis

class Forms::InputFieldComponent < ApplicationComponent

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

  INPUT_BASE_CLASSES = %w[
    placeholder:text-muted bg-input border border-border pr-6 h-9 w-full
    min-w-0 rounded-base px-3 py-1 text-sm transition-[color,box-shadow]
    disabled:pointer-events-none disabled:cursor-not-allowed disabled:opacity-50
    aria-invalid:ring-danger-600/20 aria-invalid:border-danger
  ].join(" ").freeze

  INPUT_HOVER_CLASSES = "hover:bg-table-hover"

  INPUT_FOCUS_CLASSES = %w[
    focus-visible:border-border focus-visible:ring-1
    focus-visible:ring-primary-600/20 focus-visible:outline-primary-600
    focus-visible:outline-1 focus-visible:outline-offset-2
  ].join(" ").freeze

  INPUT_ERROR_CLASSES = %w[
    !border-danger ring-1 ring-danger-600/20 focus-visible:!outline-danger-600
  ].join(" ").freeze

  INPUT_MONO_CLASSES  = "!font-mono placeholder:!font-mono"
  INPUT_SMALL_CLASSES = "!h-fit !w-fit !px-2.5 !py-0.75"

  DESC_BASE_CLASSES = %w[
    flex items-center gap-1.5 text-xs text-muted leading-none font-normal
    select-none
    group-data-[disabled=true]:pointer-events-none
    group-data-[disabled=true]:opacity-50
    peer-disabled:cursor-not-allowed
    peer-disabled:opacity-50
  ].join(" ").freeze

  DESC_ERROR_CLASSES = "!text-danger-600 w-fit"

  # ==========================================================================
  # INITIALIZATION
  # ==========================================================================

  # @param f [ActionView::Helpers::FormBuilder] The Rails form builder instance.
  # @param name [Symbol] The attribute name on the model.
  # @param label [String, nil] The label text; if nil, defaults to attribute human name.
  # @param field_type [Symbol] Rails input helper (e.g., :text_field, :number_field).
  # @param placeholder [String, nil] Placeholder text for the input.
  # @param desc [String, nil] Optional help text or description.
  # @param is_half_width [Boolean] Whether to occupy 50% of the container.
  # @param is_small [Boolean] Whether to apply compact padding/height.
  # @param currency_mask [Boolean] Enables BRL currency formatting via JS.
  # @param cnpj_mask [Boolean] Enables CNPJ numeric masking via JS.
  # @param step [String, nil] The 'step' attribute for numeric inputs.
  # @param inputmode [String, nil] The 'inputmode' attribute for mobile keyboards.
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

  # @return [Boolean]
  def has_error?
    @f.object.respond_to?(:errors) && @f.object.errors[@name].present?
  end

  # @return [String, nil] The first validation error message for the field.
  def error_message
    return unless has_error?
    @f.object.errors[@name].first
  end

  # ==========================================================================
  # STYLE RESOLUTION
  # ==========================================================================

  # Combines utility classes based on field state and type.
  # @return [String]
  def full_input_classes
    classes = [INPUT_BASE_CLASSES, INPUT_HOVER_CLASSES, INPUT_FOCUS_CLASSES]
    classes << INPUT_ERROR_CLASSES  if has_error?
    classes << INPUT_MONO_CLASSES   if mono_font_required?
    classes << INPUT_SMALL_CLASSES  if @is_small
    classes.join(" ")
  end

  # Provides ID reference for accessibility.
  # @return [String, nil]
  def aria_describedby
    "#{@name}-desc" if @desc.present? || has_error?
  end

  # @return [String]
  def desc_classes
    base = DESC_BASE_CLASSES.dup
    has_error? ? "#{base} #{DESC_ERROR_CLASSES}" : base
  end

  # @return [String]
  def wrapper_width_class
    @is_half_width ? "w-full md:w-1/2" : "w-full"
  end

  private

  # @return [Boolean]
  def mono_font_required?
    @field_type == :number_field || @currency_mask || @cnpj_mask || @bank_account_mask
  end
end

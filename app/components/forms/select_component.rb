# app/components/forms/select_component.rb
# frozen_string_literal: true

# Component responsible for rendering a form-backed select dropdown with
# TomSelect enhancement, validation-aware styling, and accessibility attributes.
#
# @author Moisés Reis

class Forms::SelectComponent < ApplicationComponent

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

  DESC_BASE_CLASSES = %w[
    flex items-center gap-1.5 text-xs text-muted leading-none font-normal
    select-none
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

  # @param f                 [ActionView::Helpers::FormBuilder] Form builder instance.
  # @param name              [Symbol] The attribute name on the model.
  # @param options_collection [Array] Collection of [label, value] pairs for the select.
  # @param label             [String, nil] Label text; omitted if nil.
  # @param desc              [String, nil] Help text rendered below the field.
  # @param selected          [Object, nil] Pre-selected value.
  # @param is_inactive       [Boolean] Disables the select when true.
  # @param is_half_width     [Boolean] Constrains width to 50% of container.
  # @param is_small          [Boolean] Applies compact sizing via input-small class.
  def initialize(
    f:,
    name:,
    options_collection:,
    label: nil,
    desc: nil,
    rich: false,
    selected: nil,
    is_inactive: false,
    is_half_width: false,
    is_small: false
  )
    @f                  = f
    @name               = name
    @options_collection = options_collection
    @label              = label
    @desc               = desc
    @rich               = rich
    @selected           = selected
    @is_inactive        = is_inactive
    @is_half_width      = is_half_width
    @is_small           = is_small
  end

  # ==========================================================================
  # ERROR HANDLING
  # ==========================================================================

  # @return [Boolean]
  def has_error?
    @f.object.respond_to?(:errors) && @f.object.errors[@name].present?
  end

  # @return [String, nil]
  def error_message
    return unless has_error?
    @f.object.errors.full_messages_for(@name).first
  end

  # ==========================================================================
  # STYLE RESOLUTION
  # ==========================================================================

  # @return [String, nil]
  def wrapper_width_class
    "!w-1/2" if @is_half_width
  end

  # @return [String]
  def desc_classes
    has_error? ? "#{DESC_BASE_CLASSES} #{DESC_ERROR_CLASSES}" : DESC_BASE_CLASSES
  end

  # @return [String, nil]
  def aria_describedby
    "#{@name}-desc" if @desc.present? || has_error?
  end
end
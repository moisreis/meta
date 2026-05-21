# frozen_string_literal: true

# Shared CSS class constants for all Forms::* components.
# Include this module instead of duplicating class strings across components.
#
# Usage:
#   class Forms::MyComponent < ApplicationComponent
#     include FormStyles
#   end

module FormStyles
  # --------------------------------------------------------------------------
  # Label
  # --------------------------------------------------------------------------

  LABEL_CLASSES = %w[
    flex items-center gap-1.5 text-muted text-2xs font-mono uppercase
    tracking-widest leading-none font-medium select-none
    group-data-[disabled=true]:pointer-events-none
    group-data-[disabled=true]:opacity-50
    peer-disabled:cursor-not-allowed
    peer-disabled:opacity-50
  ].join(" ").freeze

  # --------------------------------------------------------------------------
  # Input
  # --------------------------------------------------------------------------

  INPUT_BASE_CLASSES = %w[
    placeholder:text-muted bg-input border border-border pr-6 h-9 w-full
    min-w-0 rounded-base px-3 py-1 text-sm transition-[color,box-shadow]
    disabled:pointer-events-none disabled:cursor-not-allowed disabled:opacity-50
    aria-invalid:ring-danger-600/20 aria-invalid:border-danger
  ].join(" ").freeze

  INPUT_HOVER_CLASSES = "hover:bg-table-hover"

  INPUT_FOCUS_CLASSES = %w[
    focus-visible:border-border
    focus-visible:outline-neutral-600
    focus-visible:outline-1 focus-visible:outline-offset-2
  ].join(" ").freeze

  INPUT_ERROR_CLASSES = %w[
    !border-danger ring-1 ring-danger-600/20 focus-visible:!outline-danger-600
  ].join(" ").freeze

  INPUT_SMALL_CLASSES = "!h-fit !w-fit !px-2.5 !py-0.75"

  INPUT_MONO_CLASSES = "!font-mono placeholder:!font-mono"

  # --------------------------------------------------------------------------
  # Description / help text
  # --------------------------------------------------------------------------

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

  # --------------------------------------------------------------------------
  # Textarea-specific (extends INPUT_BASE_CLASSES)
  # --------------------------------------------------------------------------

  TEXTAREA_EXTRA_CLASSES = %w[
    shadow-xs resize-none outline-none py-2
  ].join(" ").freeze

  # --------------------------------------------------------------------------
  # Shared helpers (available on any including component)
  # --------------------------------------------------------------------------

  # @return [String] Combined desc classes, with error variant when applicable.
  def desc_classes
    has_error? ? "#{DESC_BASE_CLASSES} #{DESC_ERROR_CLASSES}" : DESC_BASE_CLASSES
  end

  # @return [String, nil] aria-describedby ID when a desc or error is present.
  def aria_describedby
    "#{@name}-desc" if @desc.present? || has_error?
  end

  # @return [String] CSS class that constrains width to 50%.
  def wrapper_width_class
    @is_half_width ? "w-full md:w-1/2" : "w-full"
  end
end
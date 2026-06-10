# frozen_string_literal: true

# app/components/concerns/form_styles.rb
#
# Shared CSS class constants for all Forms::* components.
# Include this module instead of duplicating class strings across components.
#
# @author  Moisés Reis

module FormStyles

  # == Constants ==============================================================

  # -- Label Typography & State -----------------------------------------------

  LABEL_CLASSES = %w[
    flex items-center gap-1.5 text-muted text-2xs font-mono uppercase
    tracking-widest leading-none font-medium select-none
    group-data-[disabled=true]:pointer-events-none
    group-data-[disabled=true]:opacity-50
    peer-disabled:cursor-not-allowed
    peer-disabled:opacity-50
  ].join(" ").freeze

  # -- Input Structure & Interaction ------------------------------------------

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

  # -- Input Sizing & Font Alternates -----------------------------------------

  INPUT_SMALL_CLASSES = "!h-fit !w-fit !px-2.5 !py-0.75"

  INPUT_MONO_CLASSES = "!font-mono placeholder:!font-mono"

  # -- Description & Support Typography ---------------------------------------

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

  # -- Textarea Multi-line Structural Overrides -------------------------------

  TEXTAREA_EXTRA_CLASSES = %w[
    shadow-xs resize-none outline-none py-2
  ].join(" ").freeze


  # == Instance Methods =======================================================

  # -- Element Class Compilation ----------------------------------------------

  # Combined description utility classes, applying the error layout variant when applicable.
  #
  # @return [String] Compiled Tailwind CSS utility classes.
  def desc_classes
    has_error? ? "#{DESC_BASE_CLASSES} #{DESC_ERROR_CLASSES}" : DESC_BASE_CLASSES
  end

  # Returns the layout constraint class that restricts component width to half on desktop profiles.
  #
  # @return [String] Tailwind configuration string for full width or medium breakpoint half width.
  def wrapper_width_class
    @is_half_width ? "w-full md:w-1/2" : "w-full"
  end

  # -- Accessibility Helpers --------------------------------------------------

  # Generates an aria-describedby DOM targeting reference ID if an active description
  # or validation error is present.
  #
  # @return [String, nil] Unique tracking element slug, or nil if no active support labels exist.
  def aria_describedby
    "#{@name}-desc" if @desc.present? || has_error?
  end

end
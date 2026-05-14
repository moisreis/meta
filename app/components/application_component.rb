# frozen_string_literal: true

# Base component for ViewComponent-based UI elements.
#
# This component provides shared helper integration and presenter construction
# utilities for reusable UI components across the application.
#
# @author Moisés Reis

class ApplicationComponent < ViewComponent::Base

  # ==========================================================================
  # DELEGATIONS
  # ==========================================================================

  delegate :formatted_timestamp, to: :helpers

  # ==========================================================================
  # PRIVATE HELPERS
  # ==========================================================================

  private

  # Builds a presenter instance bound to Rails view helpers.
  #
  # This method standardizes presenter instantiation by injecting the
  # view context helpers, ensuring consistent rendering behavior across
  # components.
  #
  # @param presenter_class [Class] Presenter class to instantiate.
  # @param subject [Object] Domain object passed to the presenter.
  #
  # @return [Object] Instantiated presenter.
  def build_presenter(presenter_class, subject)
    presenter_class.new(subject, helpers)
  end

  # Renders an inline SVG icon from the asset pipeline.
  #
  # @param name [String, Symbol, nil] Icon filename (without extension).
  # @param options [Hash] HTML/SVG options passed to the renderer.
  #
  # @return [ActiveSupport::SafeBuffer, nil] Rendered SVG markup or nil if no name provided.
  def render_icon(name, **options)
    return unless name.present?

    helpers.inline_svg_tag("icons/#{name}.svg", **options)
  end
end

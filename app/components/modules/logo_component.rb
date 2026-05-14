# frozen_string_literal: true

# Component responsible for rendering the application logo with configurable
# size and alternative text.
#
# This component standardizes logo presentation across layouts and shared UI
# regions.
#
# @author Moisés Reis

class Modules::LogoComponent < ApplicationComponent

  # ==========================================================================
  # CONSTANTS
  # ==========================================================================

  # Default dimensions for the logo image.
  DEFAULT_SIZE = "64x64"

  # Default alternative text for accessibility.
  DEFAULT_ALT  = "Logo"

  # ==========================================================================
  # INITIALIZATION
  # ==========================================================================

  # @param size [String] Dimensions in 'widthxheight' format.
  # @param alt [String] Alternative text for screen readers and broken images.
  def initialize(size: DEFAULT_SIZE, alt: DEFAULT_ALT)
    @size = size
    @alt  = alt
  end
end

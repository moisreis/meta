# Provides centralized color palette utilities for chart rendering.
#
# This module defines reusable chart color palettes and helper methods for
# converting hexadecimal color definitions into CSS-compatible RGB and RGBA
# formats used throughout the application's data visualizations.
#
# @author Moisés Reis

module ChartPalettes

  # ==========================================================================
  # COLOR DEFINITIONS
  # ==========================================================================

  # Maps semantic color names to hexadecimal RGB color values.
  #
  # @return [Hash<Symbol, String>] Immutable mapping of color identifiers
  #   to six-character hexadecimal RGB values without the leading '#'.
  COLORS = {
    violet: "6D28D9",
    green:  "227857",
    teal:   "115E59",
    indigo: "4F46E5",
    gray:   "9CA3AF",
    red:    "B91C1C"
  }.freeze

  # ==========================================================================
  # PALETTE DEFINITIONS
  # ==========================================================================

  # Defines reusable semantic chart palettes composed of color identifiers.
  #
  # @return [Hash<Symbol, Array<Symbol>>] Immutable mapping of palette names
  #   to ordered color key collections.
  PALETTES = {
    compliance:   %i[violet green teal].freeze,
    performance:  %i[indigo gray].freeze,
    default:      %i[indigo].freeze,
    distribution: %i[indigo violet teal green gray].freeze,
    line_series:  %i[indigo gray teal violet].freeze
  }.freeze

  # ==========================================================================
  # PUBLIC API
  # ==========================================================================

  # Converts a chart palette into CSS RGB color strings.
  #
  # @param key [Symbol] Palette identifier defined in {PALETTES}.
  # @return [Array<String>] CSS-compatible RGB color strings.
  # @raise [KeyError] If the palette key does not exist.
  def self.css(key)
    resolve(key).map { |hex| hex_to_css(hex) }
  end

  # Returns hexadecimal color values for a chart palette.
  #
  # @param key [Symbol] Palette identifier defined in {PALETTES}.
  # @return [Array<String>] Hexadecimal RGB color values without '#'.
  # @raise [KeyError] If the palette key does not exist.
  def self.hex(key)
    resolve(key)
  end

  # Converts a named color into a CSS RGBA color string.
  #
  # @param key [Symbol] Color identifier defined in {COLORS}.
  # @param opacity [Float] Opacity value between 0.0 and 1.0.
  # @return [String] CSS-compatible RGBA color string.
  # @raise [KeyError] If the color key does not exist.
  def self.rgba(key, opacity = 1.0)
    hex = COLORS.fetch(key) do
      raise KeyError, "Unknown color: #{key.inspect}"
    end

    r, g, b = hex.scan(/../).map { |component| component.to_i(16) }

    "rgba(#{r}, #{g}, #{b}, #{opacity})"
  end

  private_class_method

  # ==========================================================================
  # PRIVATE METHODS
  # ==========================================================================

  # Resolves a palette key into its associated hexadecimal color values.
  #
  # @param key [Symbol] Palette identifier defined in {PALETTES}.
  # @return [Array<String>] Ordered hexadecimal RGB color values.
  # @raise [KeyError] If the palette key does not exist.
  def self.resolve(key)
    palette = PALETTES.fetch(key) do
      raise KeyError,
            "Unknown chart palette: #{key.inspect}. " \
            "Add it to ChartPalettes::PALETTES."
    end

    palette.map { |color_key| COLORS.fetch(color_key) }
  end

  # Converts a hexadecimal RGB value into a CSS RGB color string.
  #
  # @param hex [String] Six-character hexadecimal RGB value without '#'.
  # @return [String] CSS-compatible RGB color string.
  def self.hex_to_css(hex)
    r, g, b = hex.scan(/../).map { |component| component.to_i(16) }

    "rgb(#{r}, #{g}, #{b})"
  end
end

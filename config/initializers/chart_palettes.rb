# Provides named color palettes used by Chartkick chart rendering.
#
# Maps semantic palette names (e.g. :compliance, :performance)
# to ordered sequences of CSS color values. Serves as the
# single source of truth for chart colouring across the
# application.
#
# Responsibilities:
# - Define named color constants in hex format.
# - Group colours into semantic palettes for different chart types.
# - Resolve palette names to CSS rgb(...) or rgba(...) strings.
#
# This module does not configure Chartkick itself. Chartkick
# option configuration lives in config/initializers/chartkick.rb.
#
# @author Moisés Reis
module ChartPalettes

  # =============================================================
  #                          CONSTANTS
  # =============================================================

  # Named colour values in hex format (without leading #).
  #
  # @return [Hash<Symbol, String>]
  COLORS = {
    navy:       "1E3A5F",
    slate:      "334155",
    emerald:    "166534",
    steel_blue: "1D4ED8",
    charcoal:   "374151",
    crimson:    "991B1B",
    green:      "166534",
    red:        "991B1B"
  }.freeze

  # Semantic palette definitions mapping a logical name to
  # an ordered sequence of {COLORS} keys.
  #
  # @return [Hash<Symbol, Array<Symbol>>]
  PALETTES = {
    compliance:   %i[navy emerald slate].freeze,
    performance:  %i[steel_blue charcoal].freeze,
    default:      %i[steel_blue].freeze,
    distribution: %i[steel_blue navy emerald slate charcoal].freeze,
    line_series:  %i[steel_blue charcoal slate navy].freeze,
    risk:         %i[crimson charcoal].freeze
  }.freeze

  # =============================================================
  #                       PUBLIC INTERFACE
  # =============================================================

  # Resolves a palette key to an array of CSS rgb(...) strings.
  #
  # @param key [Symbol] A key in {PALETTES}.
  #
  # @return [Array<String>]
  #   CSS colour strings, e.g. ["rgb(30, 58, 95)", ...].
  def self.css(key)
    resolve(key).map { |hex| hex_to_css(hex) }
  end

  # Resolves a palette key to an array of hex colour strings.
  #
  # @param key [Symbol] A key in {PALETTES}.
  #
  # @return [Array<String>]
  #   Hex colour strings without leading #, e.g. ["1E3A5F", ...].
  def self.hex(key)
    resolve(key)
  end

  # Resolves a palette key to an array of rgba(...) strings
  # with a uniform opacity.
  #
  # @param key [Symbol] A key in {PALETTES}.
  # @param opacity [Float] Opacity value between 0.0 and 1.0.
  #
  # @return [Array<String>]
  #   CSS rgba strings, e.g. ["rgba(30, 58, 95, 0.8)", ...].
  #
  # @raise [KeyError] If key is not present in {COLORS}.
  def self.rgba(key, opacity = 1.0)
    hex = COLORS.fetch(key) do
      raise KeyError, "Unknown color: #{key.inspect}"
    end

    r, g, b = hex.scan(/../).map { |component| component.to_i(16) }

    "rgba(#{r}, #{g}, #{b}, #{opacity})"
  end

  # =============================================================
  #                          PRIVATE
  # =============================================================

  private_class_method

  # Resolves a palette key to an array of hex colour values.
  #
  # @param key [Symbol] A key in {PALETTES}.
  #
  # @return [Array<String>] Hex colour strings.
  #
  # @raise [KeyError] If the palette key is not defined.
  def self.resolve(key)
    palette = PALETTES.fetch(key) do
      raise KeyError,
            "Unknown chart palette: #{key.inspect}. " \
            "Add it to ChartPalettes::PALETTES."
    end

    palette.map { |color_key| COLORS.fetch(color_key) }
  end

  # Converts a hex colour string to a CSS rgb(...) string.
  #
  # @param hex [String] Hex colour without leading #, e.g. "1E3A5F".
  #
  # @return [String] CSS rgb string, e.g. "rgb(30, 58, 95)".
  def self.hex_to_css(hex)
    r, g, b = hex.scan(/../).map { |component| component.to_i(16) }

    "rgb(#{r}, #{g}, #{b})"
  end
end
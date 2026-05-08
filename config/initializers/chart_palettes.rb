# config/initializers/chart_palettes.rb
#
# Central registry of semantic chart color palettes used across all
# visualization rendering contexts.
#
# This module standardizes chart coloring across:
# - Chartkick / Chart.js dashboards
# - PDF rendering services (Prawn)
# - Future export pipelines
#
# DESIGN PRINCIPLES:
# - Colors are stored once in canonical hex format.
# - Call sites must never use raw color literals.
# - Palettes are semantic, not presentation-oriented.
# - Rendering layers consume format-specific helpers.
#
# CONSUMERS:
# - Dashboard::ChartListComponent
# - Portfolio dashboard charts
# - PDF reporting services
# - Export generators
#
# COLOR FORMAT STRATEGY:
# - COLORS:
#     Canonical source of truth using uppercase hex values
#     without the leading "#".
#
# - PALETTES:
#     Ordered semantic groupings mapped to chart series order.
#
# - .css:
#     Produces rgb() strings for Chart.js / CSS rendering.
#
# - .hex:
#     Produces raw hex values for PDF generators.
#
# - .rgba:
#     Produces rgba() values for dynamic opacity-based rendering.
#
# ADDING A COLOR:
# 1. Add semantic key to COLORS.
# 2. Reference the key from one or more palettes.
# 3. Never inline raw color values at call sites.
#
# ADDING A PALETTE:
# 1. Add semantic palette name to PALETTES.
# 2. Compose using existing COLORS keys.
# 3. Preserve intentional ordering.
#
# NEVER:
# - Use raw rgb()/rgba()/hex values inside views or components.
# - Create visualization-specific one-off color arrays.
# - Couple palette naming to implementation details.
#
# TABLE OF CONTENTS:
#   1. Constants & Configuration
#       1a. Canonical Color Registry
#       1b. Semantic Palette Registry
#   2. Public API
#       2a. CSS Palette Access
#       2b. Hex Palette Access
#       2c. RGBA Color Access
#   3. Private Helpers
#       3a. Palette Resolution
#       3b. Hex → CSS Conversion
#
# @author Project Team
module ChartPalettes
  # =============================================================
  #                 1. CONSTANTS & CONFIGURATION
  # =============================================================

  # =============================================================
  #                  1a. CANONICAL COLOR REGISTRY
  # =============================================================

  # Canonical semantic color registry.
  #
  # Values are uppercase hex strings without the leading "#".
  #
  # NAMING RULE:
  # Use semantic names describing responsibility or intent,
  # not visual appearance alone.
  #
  # @return [Hash<Symbol, String>]
  COLORS = {
    violet: "6D28D9", # primary accent / highlighted metrics
    green:  "227857", # positive performance / targets
    teal:   "115E59", # boundaries / legal limits
    indigo: "4F46E5", # portfolio primary series
    gray:   "9CA3AF", # benchmark / secondary comparison
    red:    "B91C1C"  # negative performance / losses
  }.freeze

  # =============================================================
  #                  1b. SEMANTIC PALETTE REGISTRY
  # =============================================================

  # Semantic chart palette registry.
  #
  # IMPORTANT:
  # Palette ordering is intentional and maps directly to:
  # - chart series ordering
  # - legend ordering
  # - PDF export rendering order
  #
  # @return [Hash<Symbol, Array<Symbol>>]
  PALETTES = {
    # actual allocation / target allocation / legal limit
    compliance: %i[violet green teal].freeze,

    # portfolio / benchmark comparison
    performance: %i[indigo gray].freeze,

    # single-series fallback palette
    default: %i[indigo].freeze,

    # generic allocation/distribution visualizations
    distribution: %i[indigo violet teal green gray].freeze,

    # multi-series line charts 
    line_series:  %i[indigo gray teal violet].freeze
  }.freeze

  # =============================================================
  #                        2. PUBLIC API
  # =============================================================

  # =============================================================
  #                    2a. CSS PALETTE ACCESS
  # =============================================================

  # Returns CSS rgb() color strings for chart rendering contexts.
  #
  # Intended primarily for:
  # - Chartkick
  # - Chart.js
  # - HTML dashboard rendering
  #
  # @param key [Symbol]
  #   Semantic palette key from {PALETTES}.
  #
  # @return [Array<String>]
  #   Array of CSS rgb() strings.
  #
  # @example
  #   ChartPalettes.css(:compliance)
  #   #=> ["rgb(109, 40, 217)", ...]
  #
  # @raise [KeyError]
  #   Raised when the palette key is unknown.
  def self.css(key)
    resolve(key).map { |hex| hex_to_css(hex) }
  end

  # =============================================================
  #                    2b. HEX PALETTE ACCESS
  # =============================================================

  # Returns canonical hex color values.
  #
  # Intended primarily for:
  # - Prawn PDF generation
  # - Export pipelines
  # - Non-CSS rendering systems
  #
  # @param key [Symbol]
  #   Semantic palette key from {PALETTES}.
  #
  # @return [Array<String>]
  #   Array of uppercase hex strings without "#".
  #
  # @example
  #   ChartPalettes.hex(:performance)
  #   #=> ["4F46E5", "9CA3AF"]
  #
  # @raise [KeyError]
  #   Raised when the palette key is unknown.
  def self.hex(key)
    resolve(key)
  end

  # =============================================================
  #                     2c. RGBA COLOR ACCESS
  # =============================================================

  # Returns a CSS rgba() color string with configurable opacity.
  #
  # Primarily used for:
  # - Per-bar conditional coloring
  # - Heatmaps
  # - Trend visualizations
  # - Dynamic chart opacity states
  #
  # @param key [Symbol]
  #   Semantic color key from {COLORS}.
  #
  # @param opacity [Float]
  #   Opacity value between 0.0 and 1.0.
  #
  # @return [String]
  #   CSS rgba() color string.
  #
  # @example
  #   ChartPalettes.rgba(:red, 0.85)
  #   #=> "rgba(185, 28, 28, 0.85)"
  #
  # @raise [KeyError]
  #   Raised when the color key is unknown.
  def self.rgba(key, opacity = 1.0)
    hex = COLORS.fetch(key) do
      raise KeyError, "Unknown color: #{key.inspect}"
    end

    r, g, b = hex.scan(/../).map { |c| c.to_i(16) }

    "rgba(#{r}, #{g}, #{b}, #{opacity})"
  end

  # =============================================================
  #                      3. PRIVATE HELPERS
  # =============================================================

  # -------------------------------------------------------------
  #                    3a. PALETTE RESOLUTION
  # -------------------------------------------------------------

  # Resolves a semantic palette into canonical hex values.
  #
  # @param key [Symbol]
  #   Palette identifier from {PALETTES}.
  #
  # @return [Array<String>]
  #
  # @raise [KeyError]
  #   Raised when palette is not registered.
  private_class_method def self.resolve(key)
    palette = PALETTES.fetch(key) do
      raise KeyError,
            "Unknown chart palette: #{key.inspect}. " \
            "Add it to ChartPalettes::PALETTES."
    end

    palette.map { |color_key| COLORS.fetch(color_key) }
  end

  # =============================================================
  #                  3b. HEX → CSS CONVERSION
  # =============================================================

  # Converts canonical hex colors into CSS rgb() strings.
  #
  # @param hex [String]
  #   Uppercase hex string without "#".
  #
  # @return [String]
  #   CSS rgb() formatted string.
  private_class_method def self.hex_to_css(hex)
    r, g, b = hex.scan(/../).map { |c| c.to_i(16) }

    "rgb(#{r}, #{g}, #{b})"
  end
end
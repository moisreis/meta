# frozen_string_literal: true

# == CardHelper
#
# @author Moisés Reis
# @project Meta Investimentos
# @added 06/04/2026
# @package Meta
# @category Helpers
#
# @description
#   Provides utility methods for determining visual states and icons within UI cards.
#   It maps numerical trends and boolean states to semantic status names and icon identifiers.
#
# @example
#   card_status_trend_for(150)
#   # => :success
#
module CardHelper
  # == card_status_trend_for
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Color Helper
  #
  # @description
  #   Determines a semantic status name based on the mathematical trend (positive,
  #   negative, or zero) of a given value.
  #
  # @param value [Numeric, Object] The value to evaluate
  # @param zero [Symbol] Status to return for zero or non-comparable values (default: :default)
  # @param positive [Symbol] Status to return for positive values (default: :success)
  # @param negative [Symbol] Status to return for negative values (default: :danger)
  # @return [Symbol] The resolved status name
  #
  # @example
  #   card_status_trend_for(-10)
  #   # => :danger
  #
  def card_status_trend_for(value, zero: :default, positive: :success, negative: :danger)
    return zero unless value.respond_to?(:<=>)

    if value.positive?
      positive
    elsif value.negative?
      negative
    else
      zero
    end
  end

  # == card_data_icon_for
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category UI Helper
  #
  # @description
  #   Returns an icon identifier string based on the numerical trend of the value.
  #
  # @param value [Numeric, Object] The value to evaluate
  # @param zero [String] Icon for zero or non-comparable values (default: "status")
  # @param positive [String] Icon for positive values (default: "trending-up")
  # @param negative [String] Icon for negative values (default: "trending-down")
  # @return [String] The icon name
  #
  # @example
  #   card_data_icon_for(5.5)
  #   # => "trending-up"
  #
  def card_data_icon_for(value, zero: "status", positive: "trending-up", negative: "trending-down")
    return zero unless value.respond_to?(:<=>)

    if value.positive?
      positive
    elsif value.negative?
      negative
    else
      zero
    end
  end

  # == card_status_boolean_for
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Color Helper
  #
  # @description
  #   Maps boolean values (true/false) to semantic status names.
  #
  # @param value [Boolean, nil] The boolean state to evaluate
  # @param positive [Symbol] Status for true (default: :success)
  # @param negative [Symbol] Status for false (default: :danger)
  # @param zero [Symbol] Status for nil or other types (default: :default)
  # @return [Symbol] The resolved status name
  #
  def card_status_boolean_for(value, positive: :success, negative: :danger, zero: :default)
    return zero if value.nil?

    case value
    when true
      binding.local_variable_get(:positive)
    when false
      binding.local_variable_get(:negative)
    else
      zero
    end
  end

  # == card_icon_boolean_for
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category UI Helper
  #
  # @description
  #   Returns a specific icon identifier based on a boolean state.
  #
  # @param value [Boolean] The state to evaluate
  # @param positive [String] Icon for true (default: "check")
  # @param negative [String] Icon for false (default: "x")
  # @param zero [String] Icon for non-boolean values (default: "status")
  # @return [String] The icon name
  #
  def card_icon_boolean_for(value, positive: "check", negative: "x", zero: "status")
    return zero unless value.is_a?(TrueClass) || value.is_a?(FalseClass)

    value ? positive : negative
  end
end

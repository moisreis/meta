# frozen_string_literal: true

module CardHelper

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

  def card_status_boolean_for(value, positive: :success, negative: :danger, zero: :default)
    return zero if value.nil?

    value ? positive : negative

    case value
    when true
      binding.local_variable_get(:positive)
    when false
      binding.local_variable_get(:negative)
    else
      zero
    end
  end

  def card_icon_boolean_for(value, positive: "check", negative: "x", zero: "status")
    return zero unless value.is_a?(TrueClass) || value.is_a?(FalseClass)

    value ? positive : negative
  end

end

# frozen_string_literal: true

# == RedemptionsHelper
#
# @author Moisés Reis
# @project Meta Investimentos
# @added 06/04/2026
# @package Meta
# @category Helpers
#
# @description
#   Provides calculation and validation logic for Redemption records. This helper
#   manages financial performance metrics, quota allocation analysis, and
#   chronological validation for investment redemptions.
#
# @example Basic usage in views
#   redemption_metrics(@redemption)
#   # => { yield_value: 1500.50, is_profit: true, ... }
#
module RedemptionsHelper
  # == redemption_yield_value
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Read
  #
  # @description
  #   Returns the yield value for the redemption, defaulting to zero if nil.
  #
  # @param redemption [Redemption] The redemption record
  # @return [Numeric] The yield value or 0
  #
  def redemption_yield_value(redemption)
    redemption.redemption_yield || 0
  end

  # == redemption_is_profit?
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Validation
  #
  # @description
  #   Checks if the redemption yielded a positive profit.
  #
  # @param redemption [Redemption] The redemption record
  # @return [Boolean] True if yield is greater than zero
  #
  # @see #redemption_yield_value
  #
  def redemption_is_profit?(redemption)
    redemption_yield_value(redemption) > 0
  end

  # == redemption_is_loss?
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Validation
  #
  # @description
  #   Checks if the redemption resulted in a financial loss.
  #
  # @param redemption [Redemption] The redemption record
  # @return [Boolean] True if yield is less than zero
  #
  # @see #redemption_yield_value
  #
  def redemption_is_loss?(redemption)
    redemption_yield_value(redemption) < 0
  end

  # == redemption_return_info
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Read
  #
  # @description
  #   Retrieves detailed return percentage information, including existence and polarity flags.
  #
  # @param redemption [Redemption] The redemption record
  # @return [Hash] Details including :percentage, :has_return, and :positive
  #
  def redemption_return_info(redemption)
    return_pct = redemption.return_percentage
    has_return = return_pct && return_pct != 0

    {
      percentage: return_pct,
      has_return: has_return,
      positive: has_return && return_pct > 0
    }
  end

  # == redemption_processing_days
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Read
  #
  # @description
  #   Calculates the number of days between the redemption request and its liquidation.
  #
  # @param redemption [Redemption] The redemption record
  # @return [Integer, nil] Number of days or nil if dates are missing
  #
  def redemption_processing_days(redemption)
    return nil unless redemption.request_date && redemption.liquidation_date

    (redemption.liquidation_date - redemption.request_date).to_i
  end

  # == redemption_allocated_total
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Read
  #
  # @description
  #   Retrieves the total number of quotas currently allocated to this redemption.
  #
  # @param redemption [Redemption] The redemption record
  # @return [Numeric] Total allocated quotas
  #
  def redemption_allocated_total(redemption)
    redemption.total_allocated_quotas
  end

  # == redemption_redeemed_total
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Read
  #
  # @description
  #   Returns the total number of quotas redeemed in this operation.
  #
  # @param redemption [Redemption] The redemption record
  # @return [Numeric] Total redeemed quotas or 0
  #
  def redemption_redeemed_total(redemption)
    redemption.redeemed_quotas || 0
  end

  # == redemption_allocation_by_app
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Read
  #
  # @description
  #   Builds a breakdown mapping application labels to the amount of quotas used from each.
  #
  # @param redemption [Redemption] The redemption record
  # @return [Hash] Map of application labels to quotas used
  #
  def redemption_allocation_by_app(redemption)
    redemption.redemption_allocations.map do |alloc|
      app_label = "App ##{alloc.application.id} (#{alloc.application.request_date.strftime('%d/%m/%Y')})"
      [app_label, alloc.quotas_used]
    end.to_h
  end

  # == redemption_total_invested
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Read
  #
  # @description
  #   Calculates the total original investment value based on the quota cost at the time of application.
  #
  # @param redemption [Redemption] The redemption record
  # @return [Numeric] Total original investment amount
  #
  def redemption_total_invested(redemption)
    redemption.redemption_allocations.sum do |alloc|
      alloc.quotas_used * alloc.application.quota_value_at_application
    end
  end

  # == redemption_net_gain
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Read
  #
  # @description
  #   Calculates the net financial gain or loss by comparing liquid redeemed value to invested capital.
  #
  # @param redemption [Redemption] The redemption record
  # @return [Numeric] Net gain (positive) or loss (negative)
  #
  # @see #redemption_total_invested
  #
  def redemption_net_gain(redemption)
    redeemed_value = redemption.redeemed_liquid_value || 0
    total_invested = redemption_total_invested(redemption)
    redeemed_value - total_invested
  end

  # == redemption_avg_quota_cost
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Read
  #
  # @description
  #   Calculates the weighted average cost per quota across all associated applications.
  #
  # @param redemption [Redemption] The redemption record
  # @return [Numeric] Average cost per quota or 0
  #
  def redemption_avg_quota_cost(redemption)
    total_invested = redemption_total_invested(redemption)

    return 0 unless total_invested > 0 && redemption.redeemed_quotas

    total_invested / redemption.redeemed_quotas
  end

  # == redemption_appreciation
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Read
  #
  # @description
  #   Calculates the percentage appreciation of the quota value relative to the average cost.
  #
  # @param redemption [Redemption] The redemption record
  # @return [Numeric, nil] Appreciation percentage or nil if calculation is impossible
  #
  def redemption_appreciation(redemption)
    avg_cost = redemption_avg_quota_cost(redemption)

    return nil unless redemption.effective_quota_value && avg_cost > 0

    ((redemption.effective_quota_value - avg_cost) / avg_cost * 100)
  end

  # == redemption_cotization_valid?
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Validation
  #
  # @description
  #   Validates that the cotization date occurred after or on the same day as the request.
  #
  # @param redemption [Redemption] The redemption record
  # @return [Boolean] True if chronological order is valid
  #
  def redemption_cotization_valid?(redemption)
    return true unless redemption.cotization_date && redemption.request_date

    redemption.cotization_date >= redemption.request_date
  end

  # == redemption_liquidation_valid?
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Validation
  #
  # @description
  #   Validates that the liquidation date occurred after or on the same day as the cotization.
  #
  # @param redemption [Redemption] The redemption record
  # @return [Boolean] True if chronological order is valid
  #
  def redemption_liquidation_valid?(redemption)
    return true unless redemption.liquidation_date && redemption.cotization_date

    redemption.liquidation_date >= redemption.cotization_date
  end

  # == redemption_sufficient_quotas?
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Validation
  #
  # @description
  #   Checks if the fund investment has enough quotas held to cover the redemption amount.
  #
  # @param redemption [Redemption] The redemption record
  # @return [Boolean] True if sufficient quotas are available
  #
  def redemption_sufficient_quotas?(redemption)
    return false unless redemption.redeemed_quotas &&
                        redemption.fund_investment.total_quotas_held

    redemption.redeemed_quotas <= redemption.fund_investment.total_quotas_held
  end

  # == redemption_validations
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Read
  #
  # @description
  #   Aggregates all validation states for the redemption into a result hash.
  #
  # @param redemption [Redemption] The redemption record
  # @return [Hash] Validation flags for dates, balance, and sufficiency
  #
  def redemption_validations(redemption)
    {
      cotization_valid: redemption_cotization_valid?(redemption),
      liquidation_valid: redemption_liquidation_valid?(redemption),
      allocations_balanced: redemption.allocations_balanced?,
      sufficient_quotas: redemption_sufficient_quotas?(redemption)
    }
  end

  # == redemption_metrics
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Read
  #
  # @description
  #   Calculates and collects all primary financial and processing metrics for a redemption.
  #
  # @param redemption [Redemption] The redemption record
  # @return [Hash] Collection of yield, gain, cost, and appreciation metrics
  #
  def redemption_metrics(redemption)
    {
      yield_value: redemption_yield_value(redemption),
      is_profit: redemption_is_profit?(redemption),
      is_loss: redemption_is_loss?(redemption),
      processing_days: redemption_processing_days(redemption),
      allocated_total: redemption_allocated_total(redemption),
      redeemed_total: redemption_redeemed_total(redemption),
      total_invested: redemption_total_invested(redemption),
      net_gain: redemption_net_gain(redemption),
      avg_quota_cost: redemption_avg_quota_cost(redemption),
      appreciation: redemption_appreciation(redemption)
    }
  end

  # == redemption_performance_data
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Read
  #
  # @description
  #   Formats redemption data into structured datasets suitable for chart visualizations.
  #
  # @param redemption [Redemption] The redemption record
  # @return [Hash] Performance datasets for composition and allocation status
  #
  def redemption_performance_data(redemption)
    metrics = redemption_metrics(redemption)

    {
      investment_vs_redemption: {
        "Valor Investido" => metrics[:total_invested],
        "Valor Resgatado" => redemption.redeemed_liquid_value || 0
      },
      composition: {
        "Capital Inicial" => metrics[:total_invested],
        "Rendimento" => metrics[:yield_value]
      },
      allocation_status: {
        "Alocadas" => metrics[:allocated_total],
        "Esperadas" => metrics[:redeemed_total]
      }
    }
  end

  # == redemption_status_text
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Read
  #
  # @description
  #   Returns localized status labels and flags for the current state of the redemption.
  #
  # @param redemption [Redemption] The redemption record
  # @return [Hash] Status info including completion flag and display text
  #
  def redemption_status_text(redemption)
    {
      completed: redemption.completed?,
      status_text: redemption.completed? ? "Finalizado" : "Em processamento",
      detail_text: redemption.completed? ? "Completo" : "Pendente"
    }
  end

  # == redemption_type_label
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Read
  #
  # @description
  #   Maps internal redemption type keys to human-readable Portuguese labels.
  #
  # @param redemption [Redemption] The redemption record
  # @return [String, nil] The localized label or nil
  #
  def redemption_type_label(redemption)
    return nil if redemption.redemption_type.blank?

    {
      "partial"   => "Parcial",
      "total"     => "Total",
      "emergency" => "Emergencial",
      "scheduled" => "Programado"
    }[redemption.redemption_type]
  end
end

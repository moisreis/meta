# frozen_string_literal: true

module RedemptionsHelper
  # Returns the yield value for the redemption
  #
  # @param redemption [Redemption] the redemption record
  # @return [Numeric] yield value or 0 if nil
  def redemption_yield_value(redemption)
    redemption.redemption_yield || 0
  end

  # Checks if the redemption yielded a profit
  #
  # @param redemption [Redemption] the redemption record
  # @return [Boolean] true if yield is positive
  def redemption_is_profit?(redemption)
    redemption_yield_value(redemption) > 0
  end

  # Checks if the redemption resulted in a loss
  #
  # @param redemption [Redemption] the redemption record
  # @return [Boolean] true if yield is negative
  def redemption_is_loss?(redemption)
    redemption_yield_value(redemption) < 0
  end

  # Returns return percentage information
  #
  # @param redemption [Redemption] the redemption record
  # @return [Hash] hash with return percentage details
  def redemption_return_info(redemption)
    return_pct = redemption.return_percentage
    has_return = return_pct && return_pct != 0

    {
      percentage: return_pct,
      has_return: has_return,
      positive: has_return && return_pct > 0
    }
  end

  # Calculates processing days for the redemption
  #
  # @param redemption [Redemption] the redemption record
  # @return [Integer, nil] number of days or nil if dates missing
  def redemption_processing_days(redemption)
    return nil unless redemption.request_date && redemption.liquidation_date

    (redemption.liquidation_date - redemption.request_date).to_i
  end

  # Calculates total allocated quotas
  #
  # @param redemption [Redemption] the redemption record
  # @return [Numeric] total allocated quotas
  def redemption_allocated_total(redemption)
    redemption.total_allocated_quotas
  end

  # Returns redeemed quotas total
  #
  # @param redemption [Redemption] the redemption record
  # @return [Numeric] total redeemed quotas or 0
  def redemption_redeemed_total(redemption)
    redemption.redeemed_quotas || 0
  end

  # Builds allocation breakdown by application
  #
  # @param redemption [Redemption] the redemption record
  # @return [Hash] hash mapping application labels to quotas used
  def redemption_allocation_by_app(redemption)
    redemption.redemption_allocations.map do |alloc|
      app_label = "App ##{alloc.application.id} (#{alloc.application.request_date.strftime('%d/%m/%Y')})"
      [app_label, alloc.quotas_used]
    end.to_h
  end

  # Calculates total amount originally invested
  #
  # @param redemption [Redemption] the redemption record
  # @return [Numeric] total invested amount
  def redemption_total_invested(redemption)
    redemption.redemption_allocations.sum do |alloc|
      alloc.quotas_used * alloc.application.quota_value_at_application
    end
  end

  # Calculates net gain or loss
  #
  # @param redemption [Redemption] the redemption record
  # @return [Numeric] net gain (positive) or loss (negative)
  def redemption_net_gain(redemption)
    redeemed_value = redemption.redeemed_liquid_value || 0
    total_invested = redemption_total_invested(redemption)
    redeemed_value - total_invested
  end

  # Calculates average quota cost
  #
  # @param redemption [Redemption] the redemption record
  # @return [Numeric] average cost per quota or 0
  def redemption_avg_quota_cost(redemption)
    total_invested = redemption_total_invested(redemption)

    return 0 unless total_invested > 0 && redemption.redeemed_quotas

    total_invested / redemption.redeemed_quotas
  end

  # Calculates quota appreciation percentage
  #
  # @param redemption [Redemption] the redemption record
  # @return [Numeric, nil] appreciation percentage or nil
  def redemption_appreciation(redemption)
    avg_cost = redemption_avg_quota_cost(redemption)

    return nil unless redemption.effective_quota_value && avg_cost > 0

    ((redemption.effective_quota_value - avg_cost) / avg_cost * 100)
  end

  # Validates cotization date chronology
  #
  # @param redemption [Redemption] the redemption record
  # @return [Boolean] true if dates are valid
  def redemption_cotization_valid?(redemption)
    return true unless redemption.cotization_date && redemption.request_date

    redemption.cotization_date >= redemption.request_date
  end

  # Validates liquidation date chronology
  #
  # @param redemption [Redemption] the redemption record
  # @return [Boolean] true if dates are valid
  def redemption_liquidation_valid?(redemption)
    return true unless redemption.liquidation_date && redemption.cotization_date

    redemption.liquidation_date >= redemption.cotization_date
  end

  # Checks if quotas are sufficient for redemption
  #
  # @param redemption [Redemption] the redemption record
  # @return [Boolean] true if sufficient quotas available
  def redemption_sufficient_quotas?(redemption)
    return false unless redemption.redeemed_quotas &&
                        redemption.fund_investment.total_quotas_held

    redemption.redeemed_quotas <= redemption.fund_investment.total_quotas_held
  end

  # Returns all validation states
  #
  # @param redemption [Redemption] the redemption record
  # @return [Hash] validation results
  def redemption_validations(redemption)
    {
      cotization_valid: redemption_cotization_valid?(redemption),
      liquidation_valid: redemption_liquidation_valid?(redemption),
      allocations_balanced: redemption.allocations_balanced?,
      sufficient_quotas: redemption_sufficient_quotas?(redemption)
    }
  end

  # Returns all calculated metrics
  #
  # @param redemption [Redemption] the redemption record
  # @return [Hash] calculated metrics
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

  # Returns performance analysis data
  #
  # @param redemption [Redemption] the redemption record
  # @return [Hash] performance data for charts
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

  # Returns status text for redemption
  #
  # @param redemption [Redemption] the redemption record
  # @return [Hash] status information
  def redemption_status_text(redemption)
    {
      completed: redemption.completed?,
      status_text: redemption.completed? ? "Finalizado" : "Em processamento",
      detail_text: redemption.completed? ? "Completo" : "Pendente"
    }
  end

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
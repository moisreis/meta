# == PerformanceCalculationJob
#
# @author Moisés Reis
# @category ActiveJob
#
# Calcula e persiste snapshots mensais de performance financeira
# com base em meses efetivamente fechados (CVM),
# utilizando o método de Dietz Modificado para tratar corretamente
# os fluxos de caixa (aplicações e resgates) ocorridos no período.
#
# == Metodologia: Dietz Modificado
#
# A rentabilidade simples (Patrimônio Final / Patrimônio Inicial - 1) é
# imprecisa em carteiras com aportes e resgates, pois esses fluxos distorcem
# o resultado — um aporte no último dia do mês inflaria artificialmente a
# rentabilidade. O método de Dietz Modificado corrige isso ao ponderar cada
# fluxo de caixa pelo tempo em que ele ficou exposto ao mercado no período.
#
# Fórmula:
#   Retorno = (PF - PI - FCL) / (PI + FCL_Ponderado)
#
# Onde:
#   PF             = Patrimônio Final (cotas no fim × cota no fim do período)
#   PI             = Patrimônio Inicial (cotas no início × cota no início do período)
#   FCL            = Fluxo de Caixa Líquido (aplicações - resgates no período)
#   FCL_Ponderado  = Σ [ FC_i × (Dias restantes após FC_i / Total de dias no período) ]
#
class PerformanceCalculationJob < ApplicationJob
  queue_as :default

  def perform(target_date: Date.yesterday)
    Rails.logger.info("[PerformanceCalculationJob] Starting for #{target_date}")

    reference_date = target_date.prev_month

    FundInvestment
      .includes(:investment_fund, :portfolio, :applications, :redemptions)
      .find_each do |fund_investment|
      calculate_snapshot!(fund_investment, reference_date)
    end

    Rails.logger.info("[PerformanceCalculationJob] Finished successfully")
  end

  private

  # == calculate_snapshot!
  #
  # Cria ou atualiza o snapshot mensal de performance do investimento
  # usando o método de Dietz Modificado para tratar fluxos de caixa
  # intra-período de forma precisa.
  #
  def calculate_snapshot!(fund_investment, reference_date)
    fund      = fund_investment.investment_fund
    portfolio = fund_investment.portfolio

    period_start = reference_date.beginning_of_month
    period_end   = reference_date.end_of_month

    quota_start = find_quota_value(fund.cnpj, period_start)
    quota_end   = find_quota_value(fund.cnpj, period_end)

    return unless quota_start && quota_end

    # == Reconstrução da posição de cotas no início e no fim do período
    #
    # Em vez de usar `total_quotas_held` (que reflete o estado atual),
    # reconstruímos a posição histórica somando aplicações e subtraindo
    # resgates até as datas relevantes. Isso garante que o cálculo de
    # rentabilidade de janeiro/2025, por exemplo, use as cotas de janeiro,
    # independente de aplicações posteriores.
    quotas_at_start = reconstruct_quotas_at(fund_investment, period_start - 1.day)
    quotas_at_end   = reconstruct_quotas_at(fund_investment, period_end)

    # Ignora períodos sem posição de entrada (investimento ainda não existia)
    return if quotas_at_start <= 0 && quotas_at_end <= 0

    initial_balance = quotas_at_start * quota_start
    final_balance   = quotas_at_end * quota_end

    # == Fluxos de caixa do período para o Dietz Modificado
    #
    # Cada aplicação é um fluxo positivo; cada resgate é um fluxo negativo.
    # Usamos `cotization_date` pois é a data em que as cotas entram/saem
    # efetivamente na carteira.
    calendar_days = (period_end - period_start).to_i + 1

    period_applications = fund_investment.applications
                                         .where(cotization_date: period_start..period_end)

    period_redemptions  = fund_investment.redemptions
                                         .where(cotization_date: period_start..period_end)

    # Fluxo de caixa líquido (sem ponderação) — usado para calcular o ganho real
    net_cash_flow = period_applications.sum(:financial_value) -
                    period_redemptions.sum(:redeemed_liquid_value)

    # Fluxo de caixa ponderado pelo tempo restante no período — denominador do Dietz
    weighted_cash_flow = BigDecimal("0")

    period_applications.each do |app|
      next unless app.cotization_date && app.financial_value

      days_remaining = (period_end - app.cotization_date).to_i
      weight         = BigDecimal(days_remaining.to_s) / BigDecimal(calendar_days.to_s)
      weighted_cash_flow += app.financial_value * weight
    end

    period_redemptions.each do |red|
      next unless red.cotization_date && red.redeemed_liquid_value

      days_remaining = (period_end - red.cotization_date).to_i
      weight         = BigDecimal(days_remaining.to_s) / BigDecimal(calendar_days.to_s)
      weighted_cash_flow -= red.redeemed_liquid_value * weight
    end

    # == Cálculo pelo método de Dietz Modificado
    #
    # earnings: ganho real, excluindo os aportes/resgates do período
    # monthly_return: percentual sobre o capital efetivamente exposto ao risco
    earnings       = final_balance - initial_balance - net_cash_flow
    denominator    = initial_balance + weighted_cash_flow
    monthly_return = percentage(earnings, denominator)

    performance = PerformanceHistory.find_or_initialize_by(
      portfolio_id:       portfolio.id,
      fund_investment_id: fund_investment.id,
      period:             period_end
    )

    yearly_return = calculate_yearly_return(performance, final_balance, initial_balance)
    last_12m      = calculate_last_12_months_return(performance, final_balance)

    performance.update!(
      initial_balance:       initial_balance,
      earnings:              earnings,
      monthly_return:        monthly_return,
      yearly_return:         yearly_return,
      last_12_months_return: last_12m
    )
  end

  # == reconstruct_quotas_at
  #
  # Reconstrói a quantidade de cotas mantidas pelo fundo até uma data específica,
  # somando todas as aplicações e subtraindo todos os resgates cotizados até aquele dia.
  # Isso é necessário para que a rentabilidade histórica reflita a posição real
  # naquele momento, não o estado atual da carteira.
  #
  def reconstruct_quotas_at(fund_investment, date)
    apps = fund_investment.applications
                          .where("cotization_date <= ?", date)
                          .sum(:number_of_quotas)

    reds = fund_investment.redemptions
                          .where("cotization_date <= ?", date)
                          .sum(:redeemed_quotas)

    BigDecimal(apps.to_s) - BigDecimal(reds.to_s)
  end

  # == calculate_yearly_return
  #
  # Rentabilidade acumulada desde o primeiro snapshot do ano.
  # Usa o initial_balance do primeiro snapshot do ano como base,
  # e o final_balance do mês atual como valor corrente.
  #
  def calculate_yearly_return(performance, current_final_balance, current_initial_balance)
    year_start_snapshot = PerformanceHistory
                            .where(fund_investment_id: performance.fund_investment_id)
                            .where(
                              "period >= ? AND period < ?",
                              performance.period.beginning_of_year,
                              performance.period
                            )
                            .order(:period)
                            .first

    base_balance = year_start_snapshot&.initial_balance&.positive? ?
                     year_start_snapshot.initial_balance :
                     current_initial_balance

    return unless base_balance&.positive?

    percentage(current_final_balance - base_balance, base_balance)
  end

  # == calculate_last_12_months_return
  #
  # Rentabilidade acumulada em janela móvel de 12 meses.
  # Busca o initial_balance do snapshot mais próximo de 12 meses atrás
  # como base de comparação com o patrimônio final atual.
  #
  def calculate_last_12_months_return(performance, current_final_balance)
    snapshot_12m = PerformanceHistory
                     .where(fund_investment_id: performance.fund_investment_id)
                     .where("period <= ?", performance.period - 12.months)
                     .order(period: :desc)
                     .first

    return unless snapshot_12m&.initial_balance&.positive?

    percentage(current_final_balance - snapshot_12m.initial_balance, snapshot_12m.initial_balance)
  end

  # == find_quota_value
  #
  # Busca o valor da cota no dia ou até 5 dias anteriores
  # (tratamento de finais de semana e feriados).
  #
  def find_quota_value(cnpj, target_date)
    5.times do |offset|
      valuation = FundValuation.find_by(
        fund_cnpj: cnpj,
        date:      target_date - offset.days
      )
      return valuation.quota_value if valuation
    end

    nil
  end

  # == percentage
  #
  # Calcula percentual de forma segura, evitando divisão por zero.
  #
  def percentage(delta, base)
    return if base.nil? || base.zero?

    (delta / base) * 100
  end
end
# == PerformanceCalculationJob
#
# @author Moisés Reis
# @category ActiveJob
#
# Calcula e persiste snapshots mensais de performance financeira
# com base em meses efetivamente fechados (CVM),
# permitindo relatórios anuais e de últimos 12 meses auditáveis.
#
class PerformanceCalculationJob < ApplicationJob
  queue_as :default

  def perform(target_date: Date.yesterday)
    Rails.logger.info("[PerformanceCalculationJob] Starting for #{target_date}")

    reference_date = target_date.prev_month

    FundInvestment
      .includes(:investment_fund, :portfolio)
      .where('total_quotas_held > 0')
      .find_each do |fund_investment|
      calculate_snapshot!(fund_investment, reference_date)
    end

    Rails.logger.info("[PerformanceCalculationJob] Finished successfully")
  end

  private

  # == calculate_snapshot!
  #
  # Cria ou atualiza o snapshot mensal de performance do investimento
  # apenas para meses efetivamente encerrados
  #
  def calculate_snapshot!(fund_investment, reference_date)
    fund      = fund_investment.investment_fund
    portfolio = fund_investment.portfolio

    period_start = reference_date.beginning_of_month
    period_end   = reference_date.end_of_month

    quota_start = find_quota_value(fund.cnpj, period_start)
    quota_end   = find_quota_value(fund.cnpj, period_end)

    return unless quota_start && quota_end

    quotas = fund_investment.total_quotas_held

    initial_balance = quotas * quota_start
    final_balance   = quotas * quota_end
    earnings        = final_balance - initial_balance
    monthly_return  = percentage(earnings, initial_balance)

    performance = PerformanceHistory.find_or_initialize_by(
      portfolio_id: portfolio.id,
      fund_investment_id: fund_investment.id,
      period: period_end
    )

    yearly_return = calculate_yearly_return(performance, final_balance)
    last_12m      = calculate_last_12_months_return(performance, final_balance)

    performance.update!(
      initial_balance: initial_balance,
      final_balance: final_balance,
      earnings: earnings,
      monthly_return: monthly_return,
      yearly_return: yearly_return,
      last_12_months_return: last_12m
    )
  end

  # == calculate_yearly_return
  #
  # Rentabilidade acumulada desde o primeiro snapshot do ano
  #
  def calculate_yearly_return(performance, current_balance)
    year_start_snapshot = PerformanceHistory
                            .where(fund_investment_id: performance.fund_investment_id)
                            .where('period >= ?', performance.period.beginning_of_year)
                            .order(:period)
                            .first

    return unless year_start_snapshot&.initial_balance&.positive?

    percentage(
      current_balance - year_start_snapshot.initial_balance,
      year_start_snapshot.initial_balance
    )
  end

  # == calculate_last_12_months_return
  #
  # Rentabilidade acumulada em janela móvel de 12 meses
  #
  def calculate_last_12_months_return(performance, current_balance)
    snapshot_12m = PerformanceHistory
                     .where(fund_investment_id: performance.fund_investment_id)
                     .where('period <= ?', performance.period - 12.months)
                     .order(period: :desc)
                     .first

    return unless snapshot_12m&.final_balance&.positive?

    percentage(
      current_balance - snapshot_12m.final_balance,
      snapshot_12m.final_balance
    )
  end

  # == find_quota_value
  #
  # Busca a cota no dia ou até 5 dias anteriores
  # (tratamento de finais de semana e feriados)
  #
  def find_quota_value(cnpj, target_date)
    5.times do |offset|
      valuation = FundValuation.find_by(
        fund_cnpj: cnpj,
        date: target_date - offset.days
      )
      return valuation.quota_value if valuation
    end

    nil
  end

  # == percentage
  #
  # Calcula percentual de forma segura
  #
  def percentage(delta, base)
    return if base.zero?

    (delta / base) * 100
  end
end

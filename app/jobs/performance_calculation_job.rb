# === performance_calculation_job
#
# @author Moisés Reis
# @added 01/07/2026
# @package *Jobs*
# @description Calcula automaticamente as métricas de rentabilidade usando dados
#              de cotas (fund_valuations) e movimentações (applications/redemptions)
# @category *ActiveJob*
#
# Usage:: - Roda automaticamente todo dia após o import das cotas do CVM
#         - Calcula rentabilidade mensal, anual e últimos 12 meses
#         - Popula a tabela performance_histories
#
class PerformanceCalculationJob < ApplicationJob
  queue_as :default

  # Explanation:: Este job calcula as métricas de performance para todos os
  #               fund_investments ativos no sistema, usando as cotas do CVM
  def perform(target_date: Date.yesterday)
    start_time = Time.current

    Rails.logger.info("=" * 80)
    Rails.logger.info("[PerformanceCalculationJob] Starting calculations for #{target_date}")
    Rails.logger.info("=" * 80)

    # Busca todos os fund_investments ativos
    fund_investments = FundInvestment.includes(:investment_fund, :portfolio)
                                     .where('total_quotas_held > 0')

    total_processed = 0
    total_created = 0
    total_errors = 0

    fund_investments.find_each do |fi|
      begin
        result = calculate_performance_for_investment(fi, target_date)

        if result[:created]
          total_created += 1
          Rails.logger.info("[PerformanceCalculationJob] ✓ Created for #{fi.investment_fund.fund_name}")
        end

        total_processed += 1
      rescue StandardError => e
        total_errors += 1
        Rails.logger.error("[PerformanceCalculationJob] ✗ Error for #{fi.investment_fund.fund_name}: #{e.message}")
      end
    end

    duration = (Time.current - start_time).round(2)

    Rails.logger.info("=" * 80)
    Rails.logger.info("[PerformanceCalculationJob] ✓ CALCULATION COMPLETED")
    Rails.logger.info("=" * 80)
    Rails.logger.info("[PerformanceCalculationJob] Processed: #{total_processed}")
    Rails.logger.info("[PerformanceCalculationJob] Created: #{total_created}")
    Rails.logger.info("[PerformanceCalculationJob] Errors: #{total_errors}")
    Rails.logger.info("[PerformanceCalculationJob] Duration: #{duration} seconds")
    Rails.logger.info("=" * 80)

    {
      status: :success,
      processed: total_processed,
      created: total_created,
      errors: total_errors,
      duration_seconds: duration
    }
  end

  private

  # == calculate_performance_for_investment
  #
  # @author Moisés Reis
  # @category *Calculation*
  #
  # Calculation:: Calcula todas as métricas de performance para um fund_investment específico
  #
  def calculate_performance_for_investment(fund_investment, target_date)
    fund = fund_investment.investment_fund
    portfolio = fund_investment.portfolio

    # Busca as cotas do início e fim do período
    period_start = target_date.beginning_of_month
    period_end = target_date.end_of_month

    quota_start = find_quota_value(fund.cnpj, period_start)
    quota_end = find_quota_value(fund.cnpj, period_end)

    # Se não tiver dados de cota, não pode calcular
    return { created: false, reason: "Missing quota data" } unless quota_start && quota_end

    # Calcula rentabilidade mensal
    monthly_return = calculate_return_percentage(quota_start, quota_end)

    # Calcula rentabilidade anual (do início do ano até agora)
    year_start = Date.new(target_date.year, 1, 1)
    quota_year_start = find_quota_value(fund.cnpj, year_start)
    yearly_return = quota_year_start ? calculate_return_percentage(quota_year_start, quota_end) : nil

    # Calcula rentabilidade dos últimos 12 meses
    twelve_months_ago = target_date - 12.months
    quota_12m = find_quota_value(fund.cnpj, twelve_months_ago)
    last_12_months_return = quota_12m ? calculate_return_percentage(quota_12m, quota_end) : nil

    # Calcula o rendimento em R$ baseado na rentabilidade mensal
    earnings = calculate_earnings(fund_investment.total_invested_value, monthly_return)

    # Cria ou atualiza o registro de performance
    performance = PerformanceHistory.find_or_initialize_by(
      portfolio_id: portfolio.id,
      fund_investment_id: fund_investment.id,
      period: period_end
    )

    performance.update!(
      monthly_return: monthly_return,
      yearly_return: yearly_return,
      last_12_months_return: last_12_months_return,
      earnings: earnings
    )

    { created: true, performance: performance }
  end

  # == find_quota_value
  #
  # @author Moisés Reis
  # @category *Query*
  #
  # Query:: Busca o valor da cota mais próximo da data especificada
  #         Procura até 5 dias antes para lidar com finais de semana/feriados
  #
  def find_quota_value(cnpj, target_date)
    # Tenta encontrar a cota na data exata ou nos 5 dias anteriores
    5.times do |days_back|
      search_date = target_date - days_back.days
      valuation = FundValuation.find_by(fund_cnpj: cnpj, date: search_date)
      return valuation.quota_value if valuation
    end

    nil
  end

  # == calculate_return_percentage
  #
  # @author Moisés Reis
  # @category *Calculation*
  #
  # Calculation:: Calcula a rentabilidade percentual entre duas cotas
  #               Fórmula: ((Cota Final - Cota Inicial) / Cota Inicial) * 100
  #
  def calculate_return_percentage(quota_initial, quota_final)
    return 0 if quota_initial.zero?

    ((quota_final - quota_initial) / quota_initial) * 100
  end

  # == calculate_earnings
  #
  # @author Moisés Reis
  # @category *Calculation*
  #
  # Calculation:: Calcula o rendimento em R$ baseado na rentabilidade
  #               Fórmula: (Rentabilidade% / 100) * Valor Investido
  #
  def calculate_earnings(invested_value, return_percentage)
    return 0 if invested_value.zero? || return_percentage.nil?

    (return_percentage / 100.0) * invested_value
  end
end
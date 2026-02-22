# Primeiro, recalcula a performance
PerformanceCalculationJob.perform_now(target_date: Date.parse('2026-01-31'))

portfolio_id = 31  # Carteira MorroPrev
portfolio = Portfolio.find(portfolio_id)

puts "=" * 80
puts "DIAGNÓSTICO COMPLETO - RENTABILIDADE DA CARTEIRA"
puts "=" * 80

latest_period = portfolio.performance_histories.maximum(:period)
puts "\nPeríodo de referência: #{latest_period}"

performances = portfolio.performance_histories
                        .where(period: latest_period)
                        .includes(fund_investment: :investment_fund)
                        .order('monthly_return DESC')

puts "\n" + "=" * 80
puts "DETALHAMENTO POR FUNDO"
puts "=" * 80

total_earnings = BigDecimal('0')
weighted_return = BigDecimal('0')
total_allocation = BigDecimal('0')

performances.each_with_index do |perf, index|
  fund_name = perf.fund_investment.investment_fund.fund_name
  allocation = perf.fund_investment.percentage_allocation || BigDecimal('0')
  monthly_return = perf.monthly_return || BigDecimal('0')
  earnings = perf.earnings || BigDecimal('0')
  initial_balance = perf.initial_balance || BigDecimal('0')
  contribution = (monthly_return * allocation)

  puts "\n#{index + 1}. #{fund_name}"
  puts "   Alocação: #{allocation.round(4)}%"
  puts "   Saldo Inicial: R$ #{initial_balance.round(2)}"
  puts "   Retorno Mensal: #{monthly_return.round(4)}%"
  puts "   Rendimento: R$ #{earnings.round(2)}"
  puts "   Contribuição: #{contribution.round(6)}"

  total_earnings += earnings
  weighted_return += contribution
  total_allocation += allocation
end

puts "\n" + "=" * 80
puts "TOTAIS"
puts "=" * 80
puts "Total de Rendimentos: R$ #{total_earnings.round(2)}"
puts "Soma das Alocações: #{total_allocation.round(4)}%"
puts "Soma Ponderada: #{weighted_return.round(6)}"

puts "\n" + "=" * 80
puts "CÁLCULOS DE RENTABILIDADE"
puts "=" * 80

calculated_return = total_allocation > 0 ? (weighted_return / total_allocation) : 0
puts "\n1. MÉTODO ATUAL (Média Ponderada):"
puts "   Resultado: #{calculated_return.round(4)}%"

if total_allocation != 100
  normalized_return = weighted_return / 100
  puts "\n2. MÉTODO NORMALIZADO (Assumindo 100%):"
  puts "   Resultado: #{normalized_return.round(4)}%"
end

puts "\n" + "=" * 80
puts "VERIFICAÇÕES"
puts "=" * 80

missing_allocation = performances.select { |p| p.fund_investment.percentage_allocation.nil? }
if missing_allocation.any?
  puts "\n⚠️  #{missing_allocation.count} fundo(s) sem alocação definida:"
  missing_allocation.each { |p| puts "   - #{p.fund_investment.investment_fund.fund_name}" }
else
  puts "\n✓ Todos os fundos têm alocação definida"
end

puts "\n✓ Soma das alocações: #{total_allocation.round(2)}%"
if (total_allocation - 100).abs > 0.01
  puts "   ⚠️  Soma não é 100%. Diferença: #{(total_allocation - 100).round(4)}%"
end

puts "\n" + "=" * 80
puts "COMPARAÇÃO COM EXTRATO BB"
puts "=" * 80
puts "Esperado (soma extrato): R$ 171.898,69"
puts "Calculado pelo sistema: R$ #{total_earnings.round(2)}"
puts "Diferença: R$ #{(total_earnings - BigDecimal('171898.69')).round(2)}"
puts "=" * 80
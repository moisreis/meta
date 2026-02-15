# === DIAGNÓSTICO DETALHADO - Diferença 1.14% vs 1.08%
#
# Execute no Rails Console para ver os dados detalhados
# rails console

portfolio_id = 20  # Carteira Jacoprev
portfolio = Portfolio.find(portfolio_id)

puts "=" * 80
puts "DIAGNÓSTICO COMPLETO - RENTABILIDADE DA CARTEIRA"
puts "=" * 80

# Buscar o período mais recente
latest_period = portfolio.performance_histories.maximum(:period)
puts "\nPeríodo de referência: #{latest_period}"

# Buscar performances
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

  contribution = (monthly_return * allocation)

  puts "\n#{index + 1}. #{fund_name}"
  puts "   Alocação: #{allocation.round(4)}%"
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

# Método atual (média ponderada)
calculated_return = total_allocation > 0 ? (weighted_return / total_allocation) : 0
puts "\n1. MÉTODO ATUAL (Média Ponderada):"
puts "   Fórmula: Σ(Retorno × Alocação) / Σ(Alocação)"
puts "   Cálculo: #{weighted_return.round(6)} / #{total_allocation.round(4)}"
puts "   Resultado: #{calculated_return.round(4)}%"

# Método alternativo (assumindo 100% de alocação total)
if total_allocation != 100
  normalized_return = weighted_return / 100
  puts "\n2. MÉTODO NORMALIZADO (Assumindo 100%):"
  puts "   Fórmula: Σ(Retorno × Alocação) / 100"
  puts "   Cálculo: #{weighted_return.round(6)} / 100"
  puts "   Resultado: #{normalized_return.round(4)}%"
end

# Verificar se algum fundo não tem alocação definida
puts "\n" + "=" * 80
puts "VERIFICAÇÕES"
puts "=" * 80

missing_allocation = performances.select { |p| p.fund_investment.percentage_allocation.nil? }
if missing_allocation.any?
  puts "\n⚠️  ATENÇÃO: #{missing_allocation.count} fundo(s) sem alocação definida:"
  missing_allocation.each do |p|
    puts "   - #{p.fund_investment.investment_fund.fund_name}"
  end
else
  puts "\n✓ Todos os fundos têm alocação definida"
end

# Verificar soma das alocações
puts "\n✓ Soma das alocações: #{total_allocation.round(2)}%"
if (total_allocation - 100).abs > 0.01
  puts "   ⚠️  ATENÇÃO: A soma das alocações não é exatamente 100%"
  puts "   Diferença: #{(total_allocation - 100).round(4)}%"
end

puts "\n" + "=" * 80
puts "COMPARAÇÃO COM VALOR ESPERADO"
puts "=" * 80
puts "Esperado: 1.08%"
puts "Calculado: #{calculated_return.round(2)}%"
puts "Diferença: #{(calculated_return - 1.08).round(4)}%"

# Tentar descobrir qual seria a soma ponderada correta para 1.08%
target_return = 1.08
if total_allocation > 0
  required_weighted_sum = target_return * total_allocation / 100
  puts "\nPara obter 1.08%:"
  puts "   Soma ponderada necessária: #{required_weighted_sum.round(6)}"
  puts "   Soma ponderada atual: #{weighted_return.round(6)}"
  puts "   Diferença: #{(weighted_return - required_weighted_sum).round(6)}"
end

puts "\n" + "=" * 80
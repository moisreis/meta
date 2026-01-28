# ================================================================
# Seed para popular os dados de Performance da Carteira Jacoprev
# Baseado no PDF enviado pelo cliente
# Data de referência: Dezembro 2025
# ================================================================

puts "🔍 Buscando carteira Jacoprev..."

# Encontra a carteira Jacoprev
portfolio = Portfolio.find_by(name: "Carteira Jacoprev")

unless portfolio
  puts "❌ ERRO: Carteira Jacoprev não encontrada!"
  exit
end

puts "✅ Carteira encontrada: #{portfolio.name} (ID: #{portfolio.id})"
puts ""

# ================================================================
# DADOS DE PERFORMANCE POR FUNDO (do PDF)
# ================================================================

performance_data = [
  {
    cnpj: "10.740.670/0001-06",
    fund_name: "CAIXA BRASIL IRF-M 1",
    monthly_return: 1.13,    # Rentabilidade do Fundo (%)
    earnings: 4541.37        # Rendimento (R$)
  },
  {
    cnpj: "05.164.356/0001-84",
    fund_name: "CAIXA BRASIL TÍTULOS PÚBLICOS LP",
    monthly_return: 1.16,
    earnings: 6328.47
  },
  {
    cnpj: "23.215.097/0001-55",
    fund_name: "CAIXA BRASIL GESTÃO ESTRATÉGICA",
    monthly_return: 0.26,
    earnings: 227.62
  },
  {
    cnpj: "23.215.008/0001-70",
    fund_name: "CAIXA BRASIL MATRIZ",
    monthly_return: 1.16,
    earnings: 3415.63
  },
  {
    cnpj: "03.737.206/0001-97",
    fund_name: "CAIXA BRASIL FI REFERENCIADO DI LP",
    monthly_return: 1.22,
    earnings: 3503.95
  },
  {
    cnpj: "11.061.217/0001-28",
    fund_name: "CAIXA BRASIL IMA-GERAL",
    monthly_return: 0.76,
    earnings: 1231.63
  }
]

# Período de referência (último mês completo)
reference_period = Date.new(2025, 12, 31) # 31 de dezembro de 2025

puts "📊 Criando registros de performance..."
puts "📅 Período de referência: #{reference_period.strftime('%B %Y')}"
puts "=" * 70

created_count = 0
error_count = 0
total_earnings = 0

performance_data.each_with_index do |data, index|
  print "#{index + 1}/#{performance_data.size} - #{data[:fund_name][0..40]}... "

  # Busca o fundo pelo CNPJ
  fund = InvestmentFund.find_by(cnpj: data[:cnpj])

  unless fund
    puts "❌ Fundo não encontrado!"
    error_count += 1
    next
  end

  # Busca o FundInvestment correspondente
  fund_investment = FundInvestment.find_by(
    portfolio_id: portfolio.id,
    investment_fund_id: fund.id
  )

  unless fund_investment
    puts "❌ Alocação não encontrada!"
    error_count += 1
    next
  end

  # Verifica se já existe registro de performance para este período
  existing = PerformanceHistory.find_by(
    portfolio_id: portfolio.id,
    fund_investment_id: fund_investment.id,
    period: reference_period
  )

  if existing
    # Atualiza o registro existente
    existing.update!(
      monthly_return: data[:monthly_return],
      earnings: data[:earnings]
    )
    puts "✅ Atualizado (ID: #{existing.id})"
  else
    # Cria novo registro
    performance = PerformanceHistory.create!(
      portfolio_id: portfolio.id,
      fund_investment_id: fund_investment.id,
      period: reference_period,
      monthly_return: data[:monthly_return],
      yearly_return: nil,  # Pode ser calculado depois se necessário
      last_12_months_return: nil,  # Pode ser calculado depois se necessário
      earnings: data[:earnings]
    )
    puts "✅ Criado (ID: #{performance.id})"
    created_count += 1
  end

  total_earnings += data[:earnings]
end

puts "=" * 70
puts ""

# ================================================================
# RESUMO FINAL
# ================================================================

puts "📈 RESUMO DA PERFORMANCE"
puts "=" * 70
puts "Período: #{reference_period.strftime('%B/%Y')}"
puts "Registros criados: #{created_count}"
puts "Erros: #{error_count}"
puts ""

puts "💰 ANÁLISE DE RENDIMENTO"
puts "-" * 70
puts "Total de Rendimentos: R$ #{total_earnings.round(2)}"
puts "Valor da Carteira: R$ #{portfolio.total_invested_value.to_f.round(2)}"

# Calcula rentabilidade média da carteira
portfolio_return = (total_earnings / portfolio.total_invested_value.to_f) * 100
puts "Rentabilidade da Carteira: #{portfolio_return.round(2)}%"
puts ""

puts "📊 PERFORMANCE POR FUNDO"
puts "-" * 70

# Lista todos os registros de performance criados
PerformanceHistory.where(
  portfolio_id: portfolio.id,
  period: reference_period
).includes(fund_investment: :investment_fund).order('monthly_return DESC').each do |ph|
  fund_name = ph.fund_investment.investment_fund.fund_name
  puts "#{ph.monthly_return}% - R$ #{ph.earnings} - #{fund_name[0..50]}"
end

puts ""
puts "🎉 Seed de performance concluído!"
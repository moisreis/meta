# =============================================================================
# Seed: Fundo de Previdência Municipal de Capela do Alto Alegre-Ba
# =============================================================================
#
# Reproduz o cenário de teste para validação do método
# portfolio_return_percentage após a correção do Branch B (ponderação por EMV).
#
# Cenário:
#   - 1 portfolio com 9 fund_investments
#   - 7 fundos ativos ao final de janeiro/2026
#   - 2 fundos com resgate total em janeiro/2026 (FI66, FI67)
#   - Resultado esperado: portfolio_return_percentage = 1.29%
#
# Uso:
#   docker-compose exec web rails runner db/seeds/seed_portfolio_capela.rb
#
# Idempotente: verifica existência antes de criar. IDs gerados pelo banco.
# =============================================================================

puts "\n[Seed] Iniciando seed: Fundo de Previdência Municipal de Capela do Alto Alegre-Ba"
puts "[Seed] #{'-' * 66}"

# =============================================================================
# 1. USUÁRIO
# =============================================================================
# O seed não cria o usuário — apenas localiza o primeiro admin disponível.
# Ajuste o find_by se quiser vincular a um usuário específico.

user = User.find_by(role: "admin") || User.first

abort "[Seed] ERRO: nenhum usuário encontrado. Crie um usuário antes de rodar este seed." unless user

puts "[Seed] Usuário vinculado: #{user.email} (id=#{user.id})"

# =============================================================================
# 2. INVESTMENT FUNDS
# =============================================================================
# Os 9 fundos referenciados pelos fund_investments.
# Identificados de forma única pelo CNPJ — campo imutável e canônico.
# Se o fundo já existir, apenas reutiliza. Se não existir, cria com dados mínimos.
# Ajuste os CNPJs para os valores reais do seu ambiente de produção/dev.

puts "\n[Seed] Verificando investment funds..."

fund_seeds = [
  # label é apenas para log — não é persistido
  { label: "Fundo A  (fi_id=59, inv_fund=16)", cnpj: "00.000.016/0001-00", fund_name: "Fundo Teste A", administrator_name: "Administrador Teste" },
  { label: "Fundo B  (fi_id=60, inv_fund=14)", cnpj: "00.000.014/0001-00", fund_name: "Fundo Teste B", administrator_name: "Administrador Teste" },
  { label: "Fundo C  (fi_id=61, inv_fund=17)", cnpj: "00.000.017/0001-00", fund_name: "Fundo Teste C", administrator_name: "Administrador Teste" },
  { label: "Fundo D  (fi_id=62, inv_fund=18)", cnpj: "00.000.018/0001-00", fund_name: "Fundo Teste D", administrator_name: "Administrador Teste" },
  { label: "Fundo E  (fi_id=63, inv_fund=19)", cnpj: "00.000.019/0001-00", fund_name: "Fundo Teste E", administrator_name: "Administrador Teste" },
  { label: "Fundo F  (fi_id=64, inv_fund=20)", cnpj: "00.000.020/0001-00", fund_name: "Fundo Teste F", administrator_name: "Administrador Teste" },
  { label: "Fundo G  (fi_id=65, inv_fund=21)", cnpj: "00.000.021/0001-00", fund_name: "Fundo Teste G", administrator_name: "Administrador Teste" },
  { label: "Fundo H  (fi_id=66, inv_fund=23)", cnpj: "00.000.023/0001-00", fund_name: "Fundo Teste H", administrator_name: "Administrador Teste" },
  { label: "Fundo I  (fi_id=67, inv_fund=24)", cnpj: "00.000.024/0001-00", fund_name: "Fundo Teste I", administrator_name: "Administrador Teste" },
]

funds = fund_seeds.each_with_object({}) do |fs, map|
  fund = InvestmentFund.find_by(cnpj: fs[:cnpj])

  unless fund
    fund = InvestmentFund.create!(
      cnpj:               fs[:cnpj],
      fund_name:          fs[:fund_name],
      administrator_name: fs[:administrator_name]
    )
    puts "[Seed]   Criado: #{fs[:label]} → InvestmentFund id=#{fund.id}"
  else
    puts "[Seed]   Encontrado: #{fs[:label]} → InvestmentFund id=#{fund.id}"
  end

  map[fs[:cnpj]] = fund
end

# =============================================================================
# 3. PORTFOLIO
# =============================================================================

puts "\n[Seed] Verificando portfolio..."

PORTFOLIO_NAME = "Fundo de Previdência Municipal de Capela do Alto Alegre-Ba [SEED]"

portfolio = Portfolio.find_by(name: PORTFOLIO_NAME, user: user)

unless portfolio
  portfolio = Portfolio.create!(
    name:                 PORTFOLIO_NAME,
    user:                 user,
    annual_interest_rate: 0.4555
  )
  puts "[Seed]   Criado: Portfolio id=#{portfolio.id}"
else
  puts "[Seed]   Encontrado: Portfolio id=#{portfolio.id}"
end

# =============================================================================
# 4. FUND INVESTMENTS
# =============================================================================
# Cada fund_investment é único pela combinação portfolio + investment_fund.

puts "\n[Seed] Verificando fund investments..."

# Estrutura: cnpj do fundo => atributos do fund_investment
fi_seeds = [
  { cnpj: "00.000.016/0001-00", percentage_allocation: 2.6445,  total_invested_value: 309_278.77,    total_quotas_held: "70783.734781482271496799980225883"      },
  { cnpj: "00.000.014/0001-00", percentage_allocation: 5.2926,  total_invested_value: 618_727.67,    total_quotas_held: "19866.599199669048240123431340931"      },
  { cnpj: "00.000.017/0001-00", percentage_allocation: 43.0149, total_invested_value: 5_059_570.93,  total_quotas_held: "1142320.858121197466085014186488046"    },
  { cnpj: "00.000.018/0001-00", percentage_allocation: 17.9845, total_invested_value: 2_107_330.80,  total_quotas_held: "602669.63330721316913854935853071"       },
  { cnpj: "00.000.019/0001-00", percentage_allocation: 12.6871, total_invested_value: 1_495_057.43,  total_quotas_held: "164812.27060143144155590035579342"      },
  { cnpj: "00.000.020/0001-00", percentage_allocation: 9.6492,  total_invested_value: 1_133_144.09,  total_quotas_held: "130284.51416494336621113893277783"      },
  { cnpj: "00.000.021/0001-00", percentage_allocation: 8.7271,  total_invested_value: 1_022_443.94,  total_quotas_held: "972606.60495547643214067944458026"      },
  # FI66 e FI67: resgate total em jan/2026 → totais zerados ao final
  { cnpj: "00.000.023/0001-00", percentage_allocation: 0.0,     total_invested_value: 0.0,           total_quotas_held: "0.0"                                   },
  { cnpj: "00.000.024/0001-00", percentage_allocation: 0.0,     total_invested_value: 0.0,           total_quotas_held: "0.0"                                   },
]

# Mapeia cnpj → FundInvestment para uso nas etapas seguintes
fi_map = fi_seeds.each_with_object({}) do |fis, map|
  fund = funds[fis[:cnpj]]
  fi   = FundInvestment.find_by(portfolio: portfolio, investment_fund: fund)

  unless fi
    fi = FundInvestment.create!(
      portfolio:            portfolio,
      investment_fund:      fund,
      percentage_allocation: fis[:percentage_allocation],
      total_invested_value:  fis[:total_invested_value],
      total_quotas_held:     fis[:total_quotas_held]
    )
    puts "[Seed]   Criado: FundInvestment id=#{fi.id} (#{fund.fund_name})"
  else
    puts "[Seed]   Encontrado: FundInvestment id=#{fi.id} (#{fund.fund_name})"
  end

  map[fis[:cnpj]] = fi
end

# =============================================================================
# 5. APPLICATIONS
# =============================================================================
# Unique key: fund_investment + cotization_date + financial_value.
# Evita duplicatas em re-runs sem depender de IDs fixos.

puts "\n[Seed] Verificando applications..."

app_seeds = [
  # Aplicações iniciais de 31/dez/2025 (opening positions)
  { cnpj: "00.000.016/0001-00", cotization_date: "2025-12-31", request_date: "2025-12-31", liquidation_date: "2025-12-31", financial_value: 309_278.77,   number_of_quotas: "70783.734781482271496799980225883",    quota_value_at_application: 4.369348  },
  { cnpj: "00.000.014/0001-00", cotization_date: "2025-12-31", request_date: "2025-12-31", liquidation_date: "2025-12-31", financial_value: 618_727.67,   number_of_quotas: "19866.599199669048240123431340931",    quota_value_at_application: 31.144116 },
  { cnpj: "00.000.017/0001-00", cotization_date: "2025-12-31", request_date: "2025-12-31", liquidation_date: "2025-12-31", financial_value: 2_509_570.93, number_of_quotas: "569522.67882098180710713350396215",    quota_value_at_application: 4.406446  },
  { cnpj: "00.000.018/0001-00", cotization_date: "2025-12-31", request_date: "2025-12-31", liquidation_date: "2025-12-31", financial_value: 2_107_330.80, number_of_quotas: "602669.63330721316913854935853071",    quota_value_at_application: 3.496660  },
  { cnpj: "00.000.019/0001-00", cotization_date: "2025-12-31", request_date: "2025-12-31", liquidation_date: "2025-12-31", financial_value: 1_495_057.43, number_of_quotas: "164812.27060143144155590035579342",    quota_value_at_application: 9.071275  },
  { cnpj: "00.000.020/0001-00", cotization_date: "2025-12-31", request_date: "2025-12-31", liquidation_date: "2025-12-31", financial_value: 1_133_144.09, number_of_quotas: "130284.51416494336621113893277783",    quota_value_at_application: 8.697458  },
  { cnpj: "00.000.021/0001-00", cotization_date: "2025-12-31", request_date: "2025-12-31", liquidation_date: "2025-12-31", financial_value: 1_022_443.94, number_of_quotas: "972606.60495547643214067944458026",    quota_value_at_application: 1.051241  },
  { cnpj: "00.000.023/0001-00", cotization_date: "2025-12-31", request_date: "2025-12-31", liquidation_date: "2025-12-31", financial_value: 2_250_362.96, number_of_quotas: "578779.4917746837930330303761357",     quota_value_at_application: 3.888118  },
  { cnpj: "00.000.024/0001-00", cotization_date: "2025-12-31", request_date: "2025-12-31", liquidation_date: "2025-12-31", financial_value: 2_189_179.32, number_of_quotas: "1316546.1805847896946151718165526",    quota_value_at_application: 1.662820  },

  # Aplicações intramesais de janeiro/2026
  { cnpj: "00.000.017/0001-00", cotization_date: "2026-01-27", request_date: "2026-01-27", liquidation_date: "2026-01-27", financial_value: 2_200_000.00, number_of_quotas: "494297.60310598639333507086430183",    quota_value_at_application: 4.450760  },
  { cnpj: "00.000.017/0001-00", cotization_date: "2026-01-30", request_date: "2026-01-30", liquidation_date: "2026-01-30", financial_value: 350_000.00,   number_of_quotas: "78500.576194229265642809818224066",    quota_value_at_application: 4.458566  },
  { cnpj: "00.000.023/0001-00", cotization_date: "2026-01-20", request_date: "2026-01-20", liquidation_date: "2026-01-20", financial_value: 300_000.00,   number_of_quotas: "76587.681790436189824101071231905",    quota_value_at_application: 3.917079  },
]

# Guarda mapa cnpj+cotization_date+financial_value → Application
# para montar as redemption_allocations depois
app_map = {}

app_seeds.each do |as|
  fi  = fi_map[as[:cnpj]]
  key = [fi.id, as[:cotization_date], as[:financial_value].to_s]

  app = Application.find_by(
    fund_investment: fi,
    cotization_date: as[:cotization_date],
    financial_value: as[:financial_value]
  )

  unless app
    app = Application.create!(
      fund_investment:          fi,
      cotization_date:          as[:cotization_date],
      request_date:             as[:request_date],
      liquidation_date:         as[:liquidation_date],
      financial_value:          as[:financial_value],
      number_of_quotas:         as[:number_of_quotas],
      quota_value_at_application: as[:quota_value_at_application]
    )
    puts "[Seed]   Criada: Application id=#{app.id} | #{fi.investment_fund.fund_name} | #{as[:cotization_date]} | R$ #{as[:financial_value]}"
  else
    puts "[Seed]   Encontrada: Application id=#{app.id} | #{fi.investment_fund.fund_name} | #{as[:cotization_date]}"
  end

  app_map[key] = app
end

# =============================================================================
# 6. REDEMPTIONS + REDEMPTION ALLOCATIONS
# =============================================================================
# Resgate total de FI66 (26/jan) e FI67 (29/jan).
# Unique key: fund_investment + cotization_date + redemption_type.

puts "\n[Seed] Verificando redemptions..."

redemption_seeds = [
  {
    cnpj:                 "00.000.023/0001-00",
    cotization_date:      "2026-01-26",
    request_date:         "2026-01-26",
    liquidation_date:     "2026-01-26",
    redemption_type:      "total",
    redeemed_liquid_value: 2_572_873.68,
    redeemed_quotas:       "655367.173565119982857131447367605",
    redemption_yield:      0.0,
    # Cada allocação referencia uma application pelo índice da chave app_map
    allocations: [
      # application: FI66 aplicação de 31/dez/2025 (578779 cotas)
      { app_key: ["00.000.023/0001-00", "2025-12-31", "2250362.96"], quotas_used: "578779.4917746837930330303761357"  },
      # application: FI66 aplicação de 20/jan/2026 (76587 cotas)
      { app_key: ["00.000.023/0001-00", "2026-01-20", "300000.0"],   quotas_used: "76587.681790436189824101071231905" },
    ]
  },
  {
    cnpj:                 "00.000.024/0001-00",
    cotization_date:      "2026-01-29",
    request_date:         "2026-01-29",
    liquidation_date:     "2026-01-29",
    redemption_type:      "total",
    redeemed_liquid_value: 2_213_970.88,
    redeemed_quotas:       "1316546.1805847896946151718165526",
    redemption_yield:      0.0,
    allocations: [
      # application: FI67 aplicação de 31/dez/2025
      { app_key: ["00.000.024/0001-00", "2025-12-31", "2189179.32"], quotas_used: "1316546.1805847896946151718165526" },
    ]
  },
]

redemption_seeds.each do |rs|
  fi = fi_map[rs[:cnpj]]

  redemption = Redemption.find_by(
    fund_investment: fi,
    cotization_date: rs[:cotization_date],
    redemption_type: rs[:redemption_type]
  )

  unless redemption
    redemption = Redemption.create!(
      fund_investment:      fi,
      cotization_date:      rs[:cotization_date],
      request_date:         rs[:request_date],
      liquidation_date:     rs[:liquidation_date],
      redemption_type:      rs[:redemption_type],
      redeemed_liquid_value: rs[:redeemed_liquid_value],
      redeemed_quotas:       rs[:redeemed_quotas],
      redemption_yield:      rs[:redemption_yield]
    )
    puts "[Seed]   Criado: Redemption id=#{redemption.id} | #{fi.investment_fund.fund_name} | #{rs[:cotization_date]} | R$ #{rs[:redeemed_liquid_value]}"
  else
    puts "[Seed]   Encontrado: Redemption id=#{redemption.id} | #{fi.investment_fund.fund_name} | #{rs[:cotization_date]}"
  end

  # --- Redemption Allocations ---
  rs[:allocations].each do |alloc|
    cnpj, date, value = alloc[:app_key]
    app_fi  = fi_map[cnpj]
    app_key = [app_fi.id, date, value]
    app     = app_map[app_key]

    unless app
      puts "[Seed]   AVISO: Application não encontrada para alocação (#{alloc[:app_key].inspect}) — pulando."
      next
    end

    existing_alloc = RedemptionAllocation.find_by(
      redemption:  redemption,
      application: app
    )

    unless existing_alloc
      RedemptionAllocation.create!(
        redemption:  redemption,
        application: app,
        quotas_used: alloc[:quotas_used]
      )
      puts "[Seed]     Criada: RedemptionAllocation → redemption=#{redemption.id} | app=#{app.id} | quotas=#{alloc[:quotas_used].to_f.round(2)}"
    else
      puts "[Seed]     Encontrada: RedemptionAllocation id=#{existing_alloc.id}"
    end
  end
end

# =============================================================================
# 7. PERFORMANCE HISTORIES
# =============================================================================
# Unique key: portfolio + fund_investment + period (índice único no modelo).

puts "\n[Seed] Verificando performance histories (período: 2026-01-31)..."

PERIOD = Date.new(2026, 1, 31)

ph_seeds = [
  { cnpj: "00.000.016/0001-00", initial_balance: "309278.77",   earnings: "3621.649790094540421133770988257303695",   monthly_return: "1.1709985105329216166805665284615",  yearly_return: "1.1709985105329216166805665284615",  last_12_months_return: nil },
  { cnpj: "00.000.014/0001-00", initial_balance: "618727.67",   earnings: "7310.670106287813723786541252286516828",   monthly_return: "1.1815650827912405669180014613354",  yearly_return: "1.1815650827912405669180014613354",  last_12_months_return: nil },
  { cnpj: "00.000.017/0001-00", initial_balance: "2509570.93",  earnings: "33542.009109994901572797361393261283136",  monthly_return: "1.1828126340365909397278441628469",  yearly_return: "1.1828126340365909397278441628469",  last_12_months_return: nil },
  { cnpj: "00.000.018/0001-00", initial_balance: "2107330.80",  earnings: "27073.12526742662998404191428391655462",   monthly_return: "1.2847116963044734117700891708087",  yearly_return: "1.2847116963044734117700891708087",  last_12_months_return: nil },
  { cnpj: "00.000.019/0001-00", initial_balance: "1495057.43",  earnings: "28992.29133376840631553998748797630562",   monthly_return: "1.939209207085001832708191516628",   yearly_return: "1.939209207085001832708191516628",   last_12_months_return: nil },
  { cnpj: "00.000.020/0001-00", initial_balance: "1133144.09",  earnings: "11055.03188043793945311377186299720899",   monthly_return: "0.97560689571596666520263736829773", yearly_return: "0.97560689571596666520263736829773", last_12_months_return: nil },
  { cnpj: "00.000.021/0001-00", initial_balance: "1022443.94",  earnings: "13001.80509504480894485660281514891568",   monthly_return: "1.2716398998897493533832869912798",  yearly_return: "1.2716398998897493533832869912798",  last_12_months_return: nil },
  { cnpj: "00.000.023/0001-00", initial_balance: "2250362.96",  earnings: "22510.7200000000000000000000000143874",    monthly_return: "1.1975202398692632270934164035145",  yearly_return: "1.1975202398692632270934164035145",  last_12_months_return: nil },
  { cnpj: "00.000.024/0001-00", initial_balance: "2189179.32",  earnings: "24791.560000000000000000000000005668",     monthly_return: "1.1813064552988296989451654418398",  yearly_return: "1.1813064552988296989451654418398",  last_12_months_return: nil },
]

ph_seeds.each do |phs|
  fi = fi_map[phs[:cnpj]]

  ph = PerformanceHistory.find_by(
    portfolio:       portfolio,
    fund_investment: fi,
    period:          PERIOD
  )

  unless ph
    PerformanceHistory.create!(
      portfolio:            portfolio,
      fund_investment:      fi,
      period:               PERIOD,
      initial_balance:      phs[:initial_balance],
      earnings:             phs[:earnings],
      monthly_return:       phs[:monthly_return],
      yearly_return:        phs[:yearly_return],
      last_12_months_return: phs[:last_12_months_return]
    )
    puts "[Seed]   Criado: PerformanceHistory | #{fi.investment_fund.fund_name} | monthly_return=#{phs[:monthly_return].to_f.round(4)}%"
  else
    puts "[Seed]   Encontrado: PerformanceHistory id=#{ph.id} | #{fi.investment_fund.fund_name}"
  end
end

# =============================================================================
# 8. VERIFICAÇÃO FINAL
# =============================================================================

puts "\n[Seed] #{'-' * 66}"
puts "[Seed] Verificando resultado esperado..."

portfolio.reload

result = portfolio.portfolio_return_percentage(PERIOD).to_f.round(2)
expected = 1.29

if result == expected
  puts "[Seed] ✓ portfolio_return_percentage(2026-01-31) = #{result}% (esperado: #{expected}%)"
else
  puts "[Seed] ✗ portfolio_return_percentage(2026-01-31) = #{result}% (esperado: #{expected}%)"
  puts "[Seed]   Verifique se o método foi atualizado com a correção do Branch B."
end

yearly = portfolio.compounded_yearly_return_on(PERIOD).to_f.round(2)

if yearly == expected
  puts "[Seed] ✓ compounded_yearly_return_on(2026-01-31)  = #{yearly}% (esperado: #{expected}%)"
else
  puts "[Seed] ✗ compounded_yearly_return_on(2026-01-31)  = #{yearly}% (esperado: #{expected}%)"
end

puts "[Seed] #{'-' * 66}"
puts "[Seed] Seed concluído. Portfolio id=#{portfolio.id} — \"#{portfolio.name}\""
puts "[Seed] Acesse: /portfolios/#{portfolio.id}?reference_date=2026-01-31\n\n"
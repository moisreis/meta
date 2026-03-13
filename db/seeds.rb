# seeds_cadprev.rb
#
# Seed de teste baseado nos dados reais da carteira CadPrev OuroPrev.
# Seguro para re-executar (find_or_create_by em tudo).
#
# Uso:
#   rails runner db/seeds_cadprev.rb
#   # ou adicione um `require` no db/seeds.rb se preferir

puts "==> Seed CadPrev OuroPrev iniciado"

# =============================================================
# 1. USER (necessário como dono da carteira)
# =============================================================

user = User.find_or_create_by!(email: "cadprev_test@example.com") do |u|
  u.password              = "123456"
  u.password_confirmation = "123456"
  # Ajuste os campos abaixo conforme o teu modelo User
  u.first_name = "Felipe" if u.respond_to?(:first_name=)
  u.last_name = "Bauer" if u.respond_to?(:last_name=)
end

puts "  User: #{user.email} (id #{user.id})"

# =============================================================
# 2. INVESTMENT FUNDS
# =============================================================

funds_data = [
  { id: 3,  cnpj: "10.740.670/0001-06", fund_name: "CAIXA BRASIL IRF-M 1 TÍTULOS PÚBLICOS FUNDO DE INVESTIMENTO FINANCEIRO RENDA FIXA - RESP LIMITADA",           administrator_name: "CAIXA ECONOMICA FEDERAL", benchmark_index: "IRFM1",      administration_fee: 0.2 },
  { id: 4,  cnpj: "05.164.356/0001-84", fund_name: "CAIXA BRASIL TÍTULOS PÚBLICOS FUNDO DE INVESTIMENTO FINANCEIRO RENDA FIXA LP - RESP LIMITADA",                 administrator_name: "CAIXA ECONOMICA FEDERAL", benchmark_index: "CDI",        administration_fee: nil },
  { id: 5,  cnpj: "14.386.926/0001-71", fund_name: "CAIXA BRASIL IDKA IPCA 2A TÍTULOS PÚBLICOS FUNDO DE INVESTIMENTO FINANCEIRO RF LP - RESP LIMITADA",            administrator_name: "CAIXA ECONOMICA FEDERAL", benchmark_index: "IDKAIPCA2A", administration_fee: nil },
  { id: 6,  cnpj: "11.060.913/0001-10", fund_name: "CAIXA BRASIL IMA-B 5 TÍTULOS PÚBLICOS FUNDO DE INVESTIMENTO FINANCEIRO RENDA FIXA LP - RESP LIMITADA",         administrator_name: "CAIXA ECONOMICA FEDERAL", benchmark_index: "IMAB5",      administration_fee: nil },
  { id: 7,  cnpj: "23.215.097/0001-55", fund_name: "CAIXA BRASIL GESTÃO ESTRATÉGICA FIC DE CLASSE DE FIF RENDA FIXA - RESPONSABILIDADE LIMITADA",                  administrator_name: "CAIXA ECONOMICA FEDERAL", benchmark_index: "IPCA",       administration_fee: nil },
  { id: 8,  cnpj: "45.163.710/0001-70", fund_name: "CAIXA BRASIL IDKA PRE 2A FIC DE CLASSE DE FIF RENDA FIXA LONGO PRAZO - RESPONSABILIDADE LIMITADA",             administrator_name: "CAIXA ECONOMICA FEDERAL", benchmark_index: "IDKAPRE2A",  administration_fee: nil },
  { id: 9,  cnpj: "14.508.605/0001-00", fund_name: "CAIXA BRASIL IRF-M TÍTULOS PÚBLICOS FUNDO DE INVESTIMENTO FINANCEIRO RENDA FIXA LP - RESP LIMITADA",           administrator_name: "CAIXA ECONOMICA FEDERAL", benchmark_index: "IRMF",       administration_fee: nil },
  { id: 10, cnpj: "11.061.217/0001-28", fund_name: "CAIXA BRASIL IMA GERAL TÍTULOS PÚBLICOS FUNDO DE INVESTIMENTO FINANCEIRO RF LP - RESP LIMITADA",               administrator_name: "CAIXA ECONOMICA FEDERAL", benchmark_index: "IMAGERAL",   administration_fee: nil },
  { id: 11, cnpj: "10.740.658/0001-93", fund_name: "CAIXA BRASIL IMA-B TÍTULOS PÚBLICOS FUNDO DE INVESTIMENTO FINANCEIRO RENDA FIXA LP - RESP LIMITADA",           administrator_name: "CAIXA ECONOMICA FEDERAL", benchmark_index: "IMAB",       administration_fee: nil },
  { id: 12, cnpj: "23.215.008/0001-70", fund_name: "CAIXA BRASIL MATRIZ FUNDO DE INVESTIMENTO FINANCEIRO RENDA FIXA - RESPONSABILIDADE LIMITADA",                  administrator_name: "CAIXA ECONOMICA FEDERAL", benchmark_index: "CDI",        administration_fee: nil },
  { id: 13, cnpj: "03.737.206/0001-97", fund_name: "CAIXA BRASIL FUNDO DE INVESTIMENTO FINANCEIRO RENDA FIXA REFERENCIADO DI LONGO PRAZO - RESP LIMITADA",         administrator_name: "CAIXA ECONOMICA FEDERAL", benchmark_index: "CDI",        administration_fee: nil },
]

fund_map = {}  # cnpj => InvestmentFund record

funds_data.each do |f|
  record = InvestmentFund.find_or_create_by!(cnpj: f[:cnpj]) do |r|
    r.fund_name          = f[:fund_name]
    r.administrator_name = f[:administrator_name]
    r.benchmark_index    = f[:benchmark_index]
    r.administration_fee = f[:administration_fee]
    r.originator_fund    = ""
  end
  fund_map[f[:cnpj]] = record
  puts "  InvestmentFund: #{record.cnpj} (id #{record.id})"
end

# =============================================================
# 3. PORTFOLIO
# =============================================================

portfolio = Portfolio.find_or_create_by!(name: "CadPrev OuroPrev", user: user) do |p|
  p.annual_interest_rate = 0.0
end

puts "  Portfolio: #{portfolio.name} (id #{portfolio.id})"

# =============================================================
# 4. FUND INVESTMENTS
# =============================================================
# Mapeamento: cnpj => { total_invested_value, total_quotas_held, percentage_allocation }

fi_data = [
  { cnpj: "10.740.670/0001-06", total_invested_value: 3_402_777.50,  total_quotas_held: "800786.69169511135091573006379609",  percentage_allocation: 19.9911 },
  { cnpj: "05.164.356/0001-84", total_invested_value: 3_227_647.04,  total_quotas_held: "475315.631104860441675384586211651", percentage_allocation: 18.9653 },
  { cnpj: "14.386.926/0001-71", total_invested_value:   637_265.40,  total_quotas_held: "176794.784629092923146487329610016", percentage_allocation:  3.7478 },
  { cnpj: "11.060.913/0001-10", total_invested_value: 1_130_915.90,  total_quotas_held: "230802.0371176646559083141843452",   percentage_allocation:  6.6355 },
  { cnpj: "23.215.097/0001-55", total_invested_value: 1_859_321.94,  total_quotas_held: "804114.852780289948539049493567",    percentage_allocation: 10.9345 },
  { cnpj: "45.163.710/0001-70", total_invested_value:   516_922.09,  total_quotas_held: "365705.786873803151924408584846218", percentage_allocation:  3.0108 },
  { cnpj: "14.508.605/0001-00", total_invested_value:   637_935.45,  total_quotas_held: "180601.611536356762540470424546975", percentage_allocation:  3.7233 },
  { cnpj: "11.061.217/0001-28", total_invested_value:   737_240.07,  total_quotas_held: "162232.135551550201848779515436444", percentage_allocation:  4.3137 },
  { cnpj: "10.740.658/0001-93", total_invested_value:   733_266.65,  total_quotas_held: "148593.249930901525181470845850305", percentage_allocation:  4.3037 },
  { cnpj: "23.215.008/0001-70", total_invested_value: 1_998_267.66,  total_quotas_held: "811405.44372816442280986419915508",  percentage_allocation: 11.7609 },
  { cnpj: "03.737.206/0001-97", total_invested_value: 2_143_383.47,  total_quotas_held: "337733.93029429278199637682472507",  percentage_allocation: 12.6134 },
]

fi_map = {}  # cnpj => FundInvestment record

fi_data.each do |f|
  inv_fund = fund_map[f[:cnpj]]

  record = FundInvestment.find_or_create_by!(portfolio: portfolio, investment_fund: inv_fund) do |r|
    r.total_invested_value  = f[:total_invested_value]
    r.total_quotas_held     = BigDecimal(f[:total_quotas_held])
    r.percentage_allocation = f[:percentage_allocation]
    r.skip_allocation_validation = true
  end

  fi_map[f[:cnpj]] = record
  puts "  FundInvestment: #{inv_fund.cnpj} → fi_id #{record.id}"
end

# =============================================================
# 5. APPLICATIONS
# =============================================================

applications_data = [
  # Aplicações de 31/12/2025
  { cnpj: "10.740.670/0001-06", cotization_date: "2025-12-31", financial_value: 2_902_777.50,  number_of_quotas: "684121.02446432729463247889031448", quota_value_at_application: 4.243076  },
  { cnpj: "05.164.356/0001-84", cotization_date: "2025-12-31", financial_value: 2_727_647.04,  number_of_quotas: "402322.71725693679810270262217672", quota_value_at_application: 6.779749  },
  { cnpj: "14.386.926/0001-71", cotization_date: "2025-12-31", financial_value:   537_265.40,  number_of_quotas: "149250.33891148298775473920483588", quota_value_at_application: 3.59976   },
  { cnpj: "11.060.913/0001-10", cotization_date: "2025-12-31", financial_value:   630_915.90,  number_of_quotas: "129238.69287236561686005209566659", quota_value_at_application: 4.881788  },
  { cnpj: "23.215.097/0001-55", cotization_date: "2025-12-31", financial_value: 1_359_321.94,  number_of_quotas: "590229.40982353758510490482145338", quota_value_at_application: 2.30304   },
  { cnpj: "45.163.710/0001-70", cotization_date: "2025-12-31", financial_value:    16_922.09,  number_of_quotas: "12136.254950363684088982473453428",  quota_value_at_application: 1.394342  },
  { cnpj: "14.508.605/0001-00", cotization_date: "2025-12-31", financial_value:   137_935.45,  number_of_quotas: "39512.556406937183160805138577805",  quota_value_at_application: 3.490927  },
  { cnpj: "11.061.217/0001-28", cotization_date: "2025-12-31", financial_value:   237_240.07,  number_of_quotas: "52560.837977786383813641709064194",  quota_value_at_application: 4.513628  },
  { cnpj: "10.740.658/0001-93", cotization_date: "2025-12-31", financial_value:   233_266.65,  number_of_quotas: "47440.799836485828263343234346925",  quota_value_at_application: 4.917005  },
  { cnpj: "23.215.008/0001-70", cotization_date: "2025-12-31", financial_value: 1_998_267.66,  number_of_quotas: "811405.44372816442280986419915508",  quota_value_at_application: 2.462724  },
  { cnpj: "03.737.206/0001-97", cotization_date: "2025-12-31", financial_value: 2_143_383.47,  number_of_quotas: "337733.93029429278199637682472507",  quota_value_at_application: 6.346367  },
  # Aplicações de 27/01/2026
  { cnpj: "10.740.658/0001-93", cotization_date: "2026-01-27", financial_value:   500_000.00,  number_of_quotas: "101152.45009441569691812761150338",  quota_value_at_application: 4.943034  },
  { cnpj: "11.060.913/0001-10", cotization_date: "2026-01-27", financial_value:   500_000.00,  number_of_quotas: "101563.34424529903904826208867861",  quota_value_at_application: 4.923036  },
  { cnpj: "11.061.217/0001-28", cotization_date: "2026-01-27", financial_value:   500_000.00,  number_of_quotas: "109671.29757376381803513780637225",  quota_value_at_application: 4.559078  },
  { cnpj: "05.164.356/0001-84", cotization_date: "2026-01-27", financial_value:   500_000.00,  number_of_quotas: "72992.913847923643572681964034931",   quota_value_at_application: 6.84998   },
  { cnpj: "10.740.670/0001-06", cotization_date: "2026-01-27", financial_value:   500_000.00,  number_of_quotas: "116665.66723078405628325117348161",  quota_value_at_application: 4.285751  },
  { cnpj: "14.508.605/0001-00", cotization_date: "2026-01-27", financial_value:   500_000.00,  number_of_quotas: "141089.05512941957937966528596917",  quota_value_at_application: 3.543861  },
  { cnpj: "14.386.926/0001-71", cotization_date: "2026-01-27", financial_value:   100_000.00,  number_of_quotas: "27544.445717609935391748124774136",   quota_value_at_application: 3.630496  },
  { cnpj: "23.215.097/0001-55", cotization_date: "2026-01-27", financial_value:   500_000.00,  number_of_quotas: "213885.44295675236343414467211362",  quota_value_at_application: 2.3377    },
  { cnpj: "45.163.710/0001-70", cotization_date: "2026-01-27", financial_value:   500_000.00,  number_of_quotas: "353569.53192343946783542611139279",  quota_value_at_application: 1.414149  },
]

applications_data.each do |a|
  fi = fi_map[a[:cnpj]]
  cot_date = Date.parse(a[:cotization_date])

  Application.find_or_create_by!(
    fund_investment:  fi,
    cotization_date:  cot_date,
    financial_value:  a[:financial_value]
  ) do |r|
    r.request_date              = cot_date
    r.liquidation_date          = cot_date
    r.number_of_quotas          = BigDecimal(a[:number_of_quotas])
    r.quota_value_at_application = a[:quota_value_at_application]
  end

  puts "  Application: #{a[:cnpj]} #{a[:cotization_date]} R$#{a[:financial_value]}"
end

puts ""
puts "==> Seed concluído."
puts "    Portfolio id: #{portfolio.id}"
puts "    User email:   #{user.email} / password: password123"
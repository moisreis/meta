# ── Índices econômicos ─────────────────────────────────────────
indices = [
  { name: 'CDI',             abbreviation: 'CDI',        description: 'Certificado de Depósito Interbancário' },
  { name: 'IPCA',            abbreviation: 'IPCA',       description: 'Índice Nacional de Preços ao Consumidor Amplo' },
  { name: 'IMA-GERAL',       abbreviation: 'IMAGERAL',   description: 'Índice de Mercado ANBIMA Geral' },
  { name: 'IMA-B',           abbreviation: 'IMAB',       description: 'IMA atrelado ao IPCA' },
  { name: 'IMA-B 5',         abbreviation: 'IMAB5',      description: 'IMA-B com prazo até 5 anos' },
  { name: 'IRF-M 1',         abbreviation: 'IRFM1',      description: 'Índice de Renda Fixa de Mercado até 1 ano' },
  { name: 'IDKA IPCA 2A',    abbreviation: 'IDKAIPCA2A', description: 'Índice de Duration Constante ANBIMA IPCA 2 anos' },
  { name: 'Ibovespa',        abbreviation: 'IBOVESPA',   description: 'Índice Bovespa' },
  { name: 'Meta',            abbreviation: 'META',       description: 'Meta atuarial / benchmark da política de investimentos' },
]

indices.each do |attrs|
  idx = EconomicIndex.find_or_initialize_by(name: attrs[:name])

  idx.abbreviation = attrs[:abbreviation]
  idx.description  = attrs[:description]

  idx.save!
end


puts "✅ #{EconomicIndex.count} índices econômicos cadastrados."

# ── Valores mensais de exemplo (2025) ─────────────────────────
sample_values = {
  'CDI'        => {
    Date.new(2025,1,31) => 1.01, Date.new(2025,2,28) => 0.99,
    Date.new(2025,3,31) => 0.96, Date.new(2025,4,30) => 1.06,
    Date.new(2025,5,31) => 1.14, Date.new(2025,6,30) => 1.10
  },
  'IPCA'       => {
    Date.new(2025,1,31) => 0.16, Date.new(2025,2,28) => 1.31,
    Date.new(2025,3,31) => 0.56, Date.new(2025,4,30) => 0.43,
    Date.new(2025,5,31) => 0.26, Date.new(2025,6,30) => 0.24
  },
  'IMAGERAL'   => {
    Date.new(2025,1,31) => 1.40, Date.new(2025,2,28) => 0.79,
    Date.new(2025,3,31) => 1.27, Date.new(2025,4,30) => 1.68,
    Date.new(2025,5,31) => 1.25, Date.new(2025,6,30) => 1.27
  },
  'IBOVESPA'   => {
    Date.new(2025,1,31) => 4.86, Date.new(2025,2,28) => -2.64,
    Date.new(2025,3,31) => 6.08, Date.new(2025,4,30) => 3.69,
    Date.new(2025,5,31) => 1.45, Date.new(2025,6,30) => 1.33
  },
  'META'       => {
    Date.new(2025,1,31) => 0.56, Date.new(2025,2,28) => 1.72,
    Date.new(2025,3,31) => 0.97, Date.new(2025,4,30) => 0.84,
    Date.new(2025,5,31) => 0.66, Date.new(2025,6,30) => 0.64
  },
}

sample_values.each do |abbr, monthly|
  idx = EconomicIndex.find_by!(abbreviation: abbr)

  monthly.each do |date, value|
    EconomicIndexHistory.find_or_create_by!(
      economic_index: idx,
      date: date
    ) { |h| h.value = value }
  end
end

puts "✅ Histórico de índices inserido."

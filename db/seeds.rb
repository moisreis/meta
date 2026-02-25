# db/seeds/update_fund_articles.rb
# Atualiza benchmark_index, administration_fee e enquadramento (investment_fund_articles)
# para os 9 fundos BB do portfólio CapelaPrev III

art_i_b   = NormativeArticle.find(3)   # Art. 7º, Inciso I "b"
art_iii_a = NormativeArticle.find(5)   # Art. 7º, Inciso III "a"

funds_data = [
  {
    cnpj:             '50.099.960/0001-29',
    benchmark_index:  'IPCA',
    administration_fee: 0.06,
    article:          art_i_b
  },
  {
    cnpj:             '13.322.205/0001-35',
    benchmark_index:  'IDkA IPCA 2 ANOS',
    administration_fee: 0.20,
    article:          art_i_b
  },
  {
    cnpj:             '14.964.240/0001-10',
    benchmark_index:  'IMA',
    administration_fee: 0.20,
    article:          art_i_b
  },
  {
    cnpj:             '03.543.447/0001-03',
    benchmark_index:  'IMA-B 5',
    administration_fee: 0.20,
    article:          art_i_b
  },
  {
    cnpj:             '07.442.078/0001-05',
    benchmark_index:  'IMA-B',
    administration_fee: 0.20,
    article:          art_i_b
  },
  {
    cnpj:             '07.111.384/0001-69',
    benchmark_index:  'IRF-M',
    administration_fee: 0.20,
    article:          art_i_b
  },
  {
    cnpj:             '11.328.882/0001-35',
    benchmark_index:  'IRF-M 1',
    administration_fee: 0.30,
    article:          art_i_b
  },
  {
    cnpj:             '13.077.418/0001-49',
    benchmark_index:  'CDI',
    administration_fee: 0.30,
    article:          art_iii_a
  },
  {
    cnpj:             '35.292.588/0001-89',
    benchmark_index:  'IPCA',
    administration_fee: 0.50,
    article:          art_iii_a
  }
]

puts "Atualizando fundos BB..."

funds_data.each do |data|
  fund = InvestmentFund.find_by(cnpj: data[:cnpj])

  unless fund
    puts "  ✗ Fundo não encontrado: #{data[:cnpj]}"
    next
  end

  # 1. Atualiza campos diretos do fundo
  fund.update!(
    benchmark_index:    data[:benchmark_index],
    administration_fee: data[:administration_fee]
  )

  # 2. Substitui o artigo normativo
  fund.investment_fund_articles.destroy_all
  InvestmentFundArticle.create!(
    investment_fund_id:   fund.id,
    normative_article_id: data[:article].id
  )

  puts "  ✓ #{data[:cnpj]} → #{data[:article].article_name} | #{data[:benchmark_index]} | #{data[:administration_fee]}%"
end

puts "\nConcluído."
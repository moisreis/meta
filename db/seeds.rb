# =============================================================================
# Seed: NormativeArticles — Resolução CMN 5.272/2025
# Autor: Moisés Reis
# Descrição: Popula os artigos normativos com base nos limites por segmento
#            e nível de pró-gestão definidos na Resolução CMN 5.272/2025.
#
# Uso: rails db:seed (idempotente — usa find_or_create_by no article_number)
# =============================================================================

articles = [
  # ---------------------------------------------------------------------------
  # RENDA FIXA — limite global: 100%
  # ---------------------------------------------------------------------------
  {
    article_number:   "Art. 7° I",
    article_name:     "Fundos ou ETF 100% TPF",
    category:         "100% Títulos Públicos",
    description:      "Fundos de investimento ou ETF compostos integralmente por Títulos Públicos Federais.",
    benchmark_target: 100.0,
    minimum_target:   nil,
    maximum_target:   100.0,
    article_body:     "Sem Pró-Gestão: 100% | Nível I: 100% | Nível II: 100% | Nível III: 100% | Nível IV: 100% — Limite global cumulativo: 100%"
  },
  {
    article_number:   "Art. 7° II",
    article_name:     "TPF oferta primária",
    category:         "100% Títulos Públicos",
    description:      "Títulos Públicos Federais adquiridos em oferta primária.",
    benchmark_target: 100.0,
    minimum_target:   nil,
    maximum_target:   100.0,
    article_body:     "Sem Pró-Gestão: 100% | Nível I: 100% | Nível II: 100% | Nível III: 100% | Nível IV: 100% — Limite global cumulativo: 100%"
  },
  {
    article_number:   "Art. 7° III",
    article_name:     "TPF mercado balcão",
    category:         "100% Títulos Públicos",
    description:      "Títulos Públicos Federais negociados no mercado de balcão.",
    benchmark_target: 100.0,
    minimum_target:   nil,
    maximum_target:   100.0,
    article_body:     "Sem Pró-Gestão: Vedado | Nível I: 100% | Nível II: 100% | Nível III: 100% | Nível IV: 100% — Limite global cumulativo: 100%"
  },
  {
    article_number:   "Art. 7° IV",
    article_name:     "Operações compromissadas",
    category:         "Renda Fixa Geral",
    description:      "Operações compromissadas lastreadas em Títulos Públicos Federais.",
    benchmark_target: 5.0,
    minimum_target:   nil,
    maximum_target:   5.0,
    article_body:     "Sem Pró-Gestão: Vedado | Nível I: 5% | Nível II: 5% | Nível III: 5% | Nível IV: 5% — Limite global cumulativo: 100%"
  },
  {
    article_number:   "Art. 7° V",
    article_name:     "Fundo de Renda Fixa em Geral / ETF de Renda Fixa",
    category:         "Renda Fixa Geral",
    description:      "Fundos de investimento classificados como Renda Fixa em geral ou ETF de Renda Fixa.",
    benchmark_target: 80.0,
    minimum_target:   nil,
    maximum_target:   80.0,
    article_body:     "Sem Pró-Gestão: Vedado | Nível I: Vedado | Nível II: 80% | Nível III: 80% | Nível IV: 80% — Limite global cumulativo: 100%"
  },
  {
    article_number:   "Art. 7° VI",
    article_name:     "Ativos de Renda Fixa emitidos por IF",
    category:         "Renda Fixa Geral",
    description:      "Ativos de Renda Fixa emitidos por Instituições Financeiras (CDB, LCI, LCA etc.).",
    benchmark_target: 20.0,
    minimum_target:   nil,
    maximum_target:   20.0,
    article_body:     "Sem Pró-Gestão: Vedado | Nível I: Vedado | Nível II: 20% | Nível III: 20% | Nível IV: 20% — Limite global cumulativo: 100%"
  },
  {
    article_number:   "Art. 7° VII",
    article_name:     "Fundos de Renda Fixa – Crédito Privado",
    category:         "Renda Fixa Geral",
    description:      "Fundos de Renda Fixa com exposição a crédito privado.",
    benchmark_target: 20.0,
    minimum_target:   nil,
    maximum_target:   20.0,
    article_body:     "Sem Pró-Gestão: Vedado | Nível I: Vedado | Nível II: Vedado | Nível III: 20% | Nível IV: 20% — Limite global cumulativo: 100%"
  },
  {
    article_number:   "Art. 7° VIII",
    article_name:     "Fundos de Debêntures de Infraestrutura",
    category:         "Renda Fixa Geral",
    description:      "Fundos constituídos por debêntures incentivadas de projetos de infraestrutura (Lei 12.431).",
    benchmark_target: 20.0,
    minimum_target:   nil,
    maximum_target:   20.0,
    article_body:     "Sem Pró-Gestão: Vedado | Nível I: Vedado | Nível II: Vedado | Nível III: 20% | Nível IV: 20% — Limite global cumulativo: 35%"
  },
  {
    article_number:   "Art. 7° IX",
    article_name:     "FIDCs – Cota Sênior",
    category:         "Renda Fixa Geral",
    description:      "Fundos de Investimento em Direitos Creditórios — cotas sênior.",
    benchmark_target: 20.0,
    minimum_target:   nil,
    maximum_target:   20.0,
    article_body:     "Sem Pró-Gestão: Vedado | Nível I: Vedado | Nível II: Vedado | Nível III: Vedado | Nível IV: 20% — Limite global cumulativo: 100%"
  },

  # ---------------------------------------------------------------------------
  # RENDA VARIÁVEL — limite global: 50%
  # ---------------------------------------------------------------------------
  {
    article_number:   "Art. 8° I",
    article_name:     "Fundo de Ações em Geral",
    category:         "Renda Variável",
    description:      "Fundos de investimento classificados como Renda Variável — ações em geral.",
    benchmark_target: 40.0,
    minimum_target:   nil,
    maximum_target:   40.0,
    article_body:     "Sem Pró-Gestão: Vedado | Nível I: Vedado | Nível II: 40% | Nível III: 40% | Nível IV: 40% — Limite global cumulativo: 50%"
  },
  {
    article_number:   "Art. 8° II",
    article_name:     "ETF – Índices em Geral",
    category:         "Renda Variável",
    description:      "ETF referenciados em índices de ações em geral.",
    benchmark_target: 40.0,
    minimum_target:   nil,
    maximum_target:   40.0,
    article_body:     "Sem Pró-Gestão: Vedado | Nível I: Vedado | Nível II: 40% | Nível III: 40% | Nível IV: 40% — Limite global cumulativo: 50%"
  },
  {
    article_number:   "Art. 8° III",
    article_name:     "FI BDR de Ações e BDR de ETF Ações",
    category:         "Renda Variável",
    description:      "Fundos de investimento em BDR de ações e BDR de ETF de ações.",
    benchmark_target: 10.0,
    minimum_target:   nil,
    maximum_target:   10.0,
    article_body:     "Sem Pró-Gestão: Vedado | Nível I: Vedado | Nível II: Vedado | Nível III: 10% | Nível IV: 10% — Limite global cumulativo: 50%"
  },
  {
    article_number:   "Art. 8° IV",
    article_name:     "ETF - Internacional",
    category:         "Renda Variável",
    description:      "ETF com exposição a ativos internacionais de renda variável.",
    benchmark_target: 10.0,
    minimum_target:   nil,
    maximum_target:   10.0,
    article_body:     "Sem Pró-Gestão: Vedado | Nível I: Vedado | Nível II: Vedado | Nível III: 10% | Nível IV: 10% — Limite global cumulativo: 50%"
  },

  # ---------------------------------------------------------------------------
  # INVESTIMENTO EXTERIOR — limite global: 10%
  # ---------------------------------------------------------------------------
  {
    article_number:   "Art. 9° I",
    article_name:     "Renda Fixa – Dívida Externa",
    category:         "Investimento Exterior",
    description:      "Ativos de renda fixa classificados como dívida externa.",
    benchmark_target: 10.0,
    minimum_target:   nil,
    maximum_target:   10.0,
    article_body:     "Sem Pró-Gestão: Vedado | Nível I: Vedado | Nível II: Vedado | Nível III: 10% | Nível IV: 10% — Limite global cumulativo: 10%"
  },
  {
    article_number:   "Art. 9° II",
    article_name:     "FI +40% em FI Exterior (Inv. Qualificado)",
    category:         "Investimento Exterior",
    description:      "Fundos de investimento com mais de 40% em fundos do exterior, destinados a investidores qualificados.",
    benchmark_target: 10.0,
    minimum_target:   nil,
    maximum_target:   10.0,
    article_body:     "Sem Pró-Gestão: Vedado | Nível I: Vedado | Nível II: Vedado | Nível III: 10% | Nível IV: 10% — Limite global cumulativo: 10%"
  },
  {
    article_number:   "Art. 9° III",
    article_name:     "FI +20% em FI Exterior (Inv. Geral)",
    category:         "Investimento Exterior",
    description:      "Fundos de investimento com mais de 20% em fundos do exterior, para investidores em geral.",
    benchmark_target: 10.0,
    minimum_target:   nil,
    maximum_target:   10.0,
    article_body:     "Sem Pró-Gestão: Vedado | Nível I: Vedado | Nível II: Vedado | Nível III: 10% | Nível IV: 10% — Limite global cumulativo: 10%"
  },

  # ---------------------------------------------------------------------------
  # INVESTIMENTOS ESTRUTURADOS — limite global: 20%
  # ---------------------------------------------------------------------------
  {
    article_number:   "Art. 10° I",
    article_name:     "FI Multimercado Aberto",
    category:         "Renda Fixa Geral",
    description:      "Fundos de investimento multimercado de condomínio aberto.",
    benchmark_target: 15.0,
    minimum_target:   nil,
    maximum_target:   15.0,
    article_body:     "Sem Pró-Gestão: Vedado | Nível I: Vedado | Nível II: 15% | Nível III: 15% | Nível IV: 15% — Limite global cumulativo: 20%"
  },
  {
    article_number:   "Art. 10° II",
    article_name:     "Fiagro",
    category:         "Renda Fixa Geral",
    description:      "Fundos de Investimento nas Cadeias Produtivas Agroindustriais.",
    benchmark_target: 5.0,
    minimum_target:   nil,
    maximum_target:   5.0,
    article_body:     "Sem Pró-Gestão: Vedado | Nível I: Vedado | Nível II: Vedado | Nível III: 5% | Nível IV: 5% — Limite global cumulativo: 20%"
  },
  {
    article_number:   "Art. 10° III",
    article_name:     "FI em Participações – Fechado (Inv. Estruturados)",
    category:         "Renda Variável",
    description:      "Fundos de Investimento em Participações de condomínio fechado classificados como investimentos estruturados.",
    benchmark_target: 10.0,
    minimum_target:   nil,
    maximum_target:   10.0,
    article_body:     "Sem Pró-Gestão: Vedado | Nível I: Vedado | Nível II: Vedado | Nível III: Vedado | Nível IV: 10% — Limite global cumulativo: 20%"
  },
  {
    article_number:   "Art. 10° IV",
    article_name:     "FI em Ações Mercado de Acesso",
    category:         "Renda Variável",
    description:      "Fundos de Investimento em Ações voltados ao mercado de acesso (empresas emergentes).",
    benchmark_target: 10.0,
    minimum_target:   nil,
    maximum_target:   10.0,
    article_body:     "Sem Pró-Gestão: Vedado | Nível I: Vedado | Nível II: Vedado | Nível III: Vedado | Nível IV: 10% — Limite global cumulativo: 20%"
  },

  # ---------------------------------------------------------------------------
  # INVESTIMENTOS IMOBILIÁRIOS — limite global: 20%
  # ---------------------------------------------------------------------------
  {
    article_number:   "Art. 11°",
    article_name:     "FI Imobiliários",
    category:         "Renda Variável",
    description:      "Fundos de Investimento Imobiliário (FII).",
    benchmark_target: 20.0,
    minimum_target:   nil,
    maximum_target:   20.0,
    article_body:     "Sem Pró-Gestão: Vedado | Nível I: Vedado | Nível II: Vedado | Nível III: 20% | Nível IV: 20% — Limite global cumulativo: 20%"
  },

  # ---------------------------------------------------------------------------
  # CONSIGNADOS — limite global: 10%
  # ---------------------------------------------------------------------------
  {
    article_number:   "Art. 12°",
    article_name:     "Empréstimos Consignados",
    category:         "Renda Fixa Geral",
    description:      "Operações de empréstimo consignado a servidores públicos ou beneficiários de regimes próprios.",
    benchmark_target: 10.0,
    minimum_target:   nil,
    maximum_target:   10.0,
    article_body:     "Sem Pró-Gestão: 5% | Nível I: 10% | Nível II: 10% | Nível III: 10% | Nível IV: 10% — Limite global cumulativo: 10%"
  }
]

puts "→ Populando NormativeArticles (Resolução CMN 5.272/2025)..."

articles.each do |attrs|
  record = NormativeArticle.find_or_initialize_by(article_number: attrs[:article_number])

  if record.new_record?
    record.assign_attributes(attrs)
    record.save!
    puts "  [CRIADO]     #{attrs[:article_number]} — #{attrs[:article_name]}"
  else
    record.update!(attrs)
    puts "  [ATUALIZADO] #{attrs[:article_number]} — #{attrs[:article_name]}"
  end
end

puts "✓ #{articles.size} artigos normativos processados."
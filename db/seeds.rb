# frozen_string_literal: true
# =============================================================================
# Seed: InvestmentFund + InvestmentFundArticle associations
# Source: normative_articles_rows.json + economic_indices_rows.json
# =============================================================================

# ---------------------------------------------------------------------------
# Helper: map "Enquadramento 4.963/21" string → normative_article_id
# ---------------------------------------------------------------------------
ENQUADRAMENTO_MAP = {
  'Art. 7º, Inciso I "b"'          => 28, # Fundos ou ETF 100% TPF
  'Art. 7º,  Inciso III "a"'       => 32, # Fundo de Renda Fixa em Geral / ETF RF
  'Artigo 7º, Inciso V, "b"'       => 34, # Fundos de RF – Crédito Privado
  'Art. 8º, Inciso I'              => 37, # Fundo de Ações em Geral
  'Art. 9º - Inciso II'            => 42, # FI +40% em FI Exterior (Inv. Qualificado)
  'Art. 9º - Inciso III'           => 43, # FI +20% em FI Exterior (Inv. Geral)
  'Art. 10º, Inciso I'             => 44, # FI Multimercado Aberto
  'Art. 11º'                       => 48, # FI Imobiliários
  'Art. 7º, Inciso IV'             => 33  # Ativos de RF emitidos por IF (CDB)
}.freeze

# ---------------------------------------------------------------------------
# Helper: map "Índice de Referência" string → economic_index abbreviation
# (only indices that exist in the economic_indices table)
# ---------------------------------------------------------------------------
BENCHMARK_MAP = {
  'CDI'          => 'CDI',
  'IMA-B'        => 'IMAB',
  'IMA GERAL'    => 'IMAGERAL',
  'IMA-B5'       => 'IMAB5',
  'IRF M 1'      => 'IRFM1',
  'IDKA IPCA 2A' => 'IDKAIPCA2A',
  'IRF M'        => 'IRMF',
  'IPCA'         => 'IPCA',
  'IDKA PRE 2A'  => 'IDKAPRE2A',
  'IMA-B 5+'     => nil,   # Not in economic_indices
  'IRF M 1+'     => nil,   # Not in economic_indices
  'IBOVESPA'     => nil,
  'IBX-50'       => nil,
  'IDIV'         => nil,
  'IMOB'         => nil,
  'INFRA'        => nil,
  'SMLL'         => nil,
  'PETRO'        => nil,
  'VALE'         => nil,
  'ISE'          => nil,
  'ICON'         => nil,
  'IFIX'         => nil,
  'IDkA IPCA 5 ANOS' => nil,
  'IDkA IPCA 2 ANOS' => nil,
  'IMA-GERAL ex-C'   => nil,
  'IMA-B 5'      => 'IMAB5',
  'IMA-B5+'      => nil
}.freeze

# ---------------------------------------------------------------------------
# Fund data
# ---------------------------------------------------------------------------
funds = [
  {
    fund_name: "CAIXA BRASIL TÍTULOS PÚBLICOS FI RENDA FIXA LP",
    cnpj: "05.164.356/0001-84",
    administrator_name: "Caixa Econômica Federal",
    administration_fee: 0.20,
    performance_fee: nil,
    benchmark_index: "CDI",
    enquadramento: 'Art. 7º, Inciso I "b"'
  },
  {
    fund_name: "CAIXA RS TÍTULOS PÚBLICOS FI RENDA FIXA LP",
    cnpj: "05.164.364/0001-20",
    administrator_name: "Caixa Econômica Federal",
    administration_fee: 0.20,
    performance_fee: nil,
    benchmark_index: nil,
    enquadramento: 'Art. 7º, Inciso I "b"'
  },
  {
    fund_name: "CAIXA ALIANÇA TÍTULOS PÚBLICOS FI RENDA FIXA",
    cnpj: "05.164.358/0001-73",
    administrator_name: "Caixa Econômica Federal",
    administration_fee: 0.20,
    performance_fee: nil,
    benchmark_index: nil,
    enquadramento: 'Art. 7º, Inciso I "b"'
  },
  {
    fund_name: "CAIXA BRASIL DISPONIBILIDADES FIC RENDA FIXA",
    cnpj: "14.508.643/0001-55",
    administrator_name: "Caixa Econômica Federal",
    administration_fee: 0.80,
    performance_fee: nil,
    benchmark_index: nil,
    enquadramento: 'Art. 7º, Inciso I "b"'
  },
  {
    fund_name: "CAIXA MASTER LIQUIDEZ FI RENDA FIXA CURTO PRAZO",
    cnpj: "04.150.666/0001-87",
    administrator_name: "Caixa Econômica Federal",
    administration_fee: 0.00,
    performance_fee: nil,
    benchmark_index: nil,
    enquadramento: 'Art. 7º, Inciso I "b"'
  },
  {
    fund_name: "CAIXA BRASIL 2022 I TÍTULOS PÚBLICOS FI RENDA FIXA",
    cnpj: "18.598.117/0001-84",
    administrator_name: "Caixa Econômica Federal",
    administration_fee: 0.20,
    performance_fee: nil,
    benchmark_index: nil,
    enquadramento: 'Art. 7º, Inciso I "b"'
  },
  {
    fund_name: "CAIXA BRASIL 2024 II TÍTULOS PÚBLICOS FI RENDA FIXA",
    cnpj: "18.598.088/0001-50",
    administrator_name: "Caixa Econômica Federal",
    administration_fee: 0.20,
    performance_fee: nil,
    benchmark_index: nil,
    enquadramento: 'Art. 7º, Inciso I "b"'
  },
  {
    fund_name: "CAIXA BRASIL 2030 I TÍTULOS PÚBLICOS FI RENDA FIXA",
    cnpj: "18.598.042/0001-31",
    administrator_name: "Caixa Econômica Federal",
    administration_fee: 0.20,
    performance_fee: nil,
    benchmark_index: nil,
    enquadramento: 'Art. 7º, Inciso I "b"'
  },
  {
    fund_name: "CAIXA BRASIL IMA-B TÍTULOS PÚBLICOS FI RENDA FIXA LP",
    cnpj: "10.740.658/0001-93",
    administrator_name: "Caixa Econômica Federal",
    administration_fee: 0.20,
    performance_fee: nil,
    benchmark_index: "IMA-B",
    enquadramento: 'Art. 7º, Inciso I "b"'
  },
  {
    fund_name: "CAIXA BRASIL IMA-GERAL TÍTULOS PÚBLICOS FI RF LP",
    cnpj: "11.061.217/0001-28",
    administrator_name: "Caixa Econômica Federal",
    administration_fee: 0.20,
    performance_fee: nil,
    benchmark_index: "IMA GERAL",
    enquadramento: 'Art. 7º, Inciso I "b"'
  },
  {
    fund_name: "CAIXA BRASIL IMA-B 5 TÍTULOS PÚBLICOS FI RENDA FIXA LP",
    cnpj: "11.060.913/0001-10",
    administrator_name: "Caixa Econômica Federal",
    administration_fee: 0.20,
    performance_fee: nil,
    benchmark_index: "IMA-B5",
    enquadramento: 'Art. 7º, Inciso I "b"'
  },
  {
    fund_name: "CAIXA BRASIL IRF-M 1 TÍTULOS PÚBLICOS FI RENDA FIXA",
    cnpj: "10.740.670/0001-06",
    administrator_name: "Caixa Econômica Federal",
    administration_fee: 0.20,
    performance_fee: nil,
    benchmark_index: "IRF M 1",
    enquadramento: 'Art. 7º, Inciso I "b"'
  },
  {
    fund_name: "CAIXA BRASIL IMA-B 5+ TÍTULOS PÚBLICOS FI RENDA FIXA LP",
    cnpj: "10.577.503/0001-88",
    administrator_name: "Caixa Econômica Federal",
    administration_fee: 0.20,
    performance_fee: nil,
    benchmark_index: nil, # IMA-B 5+ not in economic_indices
    enquadramento: 'Art. 7º, Inciso I "b"'
  },
  {
    fund_name: "CAIXA BRASIL IRF-M 1+ TÍTULOS PÚBLICOS FI RENDA FIXA LP",
    cnpj: "10.577.519/0001-90",
    administrator_name: "Caixa Econômica Federal",
    administration_fee: 0.20,
    performance_fee: nil,
    benchmark_index: nil, # IRF M 1+ not in economic_indices
    enquadramento: 'Art. 7º, Inciso I "b"'
  },
  {
    fund_name: "CAIXA BRASIL IDKA IPCA 2A TP FI RF LP",
    cnpj: "14.386.926/0001-71",
    administrator_name: "Caixa Econômica Federal",
    administration_fee: 0.20,
    performance_fee: nil,
    benchmark_index: "IDKA IPCA 2A",
    enquadramento: 'Art. 7º, Inciso I "b"'
  },
  {
    fund_name: "CAIXA BRASIL IRF-M TÍTULOS PÚBLICOS FI RENDA FIXA LP",
    cnpj: "14.508.605/0001-00",
    administrator_name: "Caixa Econômica Federal",
    administration_fee: 0.20,
    performance_fee: nil,
    benchmark_index: "IRF M",
    enquadramento: 'Art. 7º, Inciso I "b"'
  },
  {
    fund_name: "CAIXA BRASIL GESTÃO ESTRATÉGICA FIC RENDA FIXA",
    cnpj: "23.215.097/0001-55",
    administrator_name: "Caixa Econômica Federal",
    administration_fee: 0.40,
    performance_fee: nil,
    benchmark_index: "IPCA",
    enquadramento: 'Art. 7º, Inciso I "b"'
  },
  {
    fund_name: "CAIXA BRASIL FI RENDA FIXA REFERENCIADO DI LP",
    cnpj: "03.737.206/0001-97",
    administrator_name: "Caixa Econômica Federal",
    administration_fee: 0.20,
    performance_fee: nil,
    benchmark_index: "CDI",
    enquadramento: 'Art. 7º,  Inciso III "a"'
  },
  {
    fund_name: "CAIXA BRASIL MATRIZ FI RENDA FIXA",
    cnpj: "23.215.008/0001-70",
    administrator_name: "Caixa Econômica Federal",
    administration_fee: 0.20,
    performance_fee: nil,
    benchmark_index: "CDI",
    enquadramento: 'Art. 7º,  Inciso III "a"'
  },
  {
    fund_name: "CAIXA BRASIL ATIVA FIC RENDA FIXA LP",
    cnpj: "35.536.532/0001-22",
    administrator_name: "Caixa Econômica Federal",
    administration_fee: 0.40,
    performance_fee: nil,
    benchmark_index: "IPCA",
    enquadramento: 'Art. 7º,  Inciso III "a"'
  },
  {
    fund_name: "CAIXA MASTER ATIVA FI RENDA FIXA LP",
    cnpj: "35.536.520/0001-06",
    administrator_name: "Caixa Econômica Federal",
    administration_fee: 0.00,
    performance_fee: nil,
    benchmark_index: nil,
    enquadramento: 'Art. 7º,  Inciso III "a"'
  },
  {
    fund_name: "CAIXA NOVO BRASIL FIC RENDA FIXA REFERENCIADO IMA-B LP",
    cnpj: "10.646.895/0001-90",
    administrator_name: "Caixa Econômica Federal",
    administration_fee: 0.20,
    performance_fee: nil,
    benchmark_index: "IMA-B",
    enquadramento: 'Art. 7º,  Inciso III "a"'
  },
  {
    fund_name: "CAIXA MASTER BRASIL FI RENDA FIXA REFERENCIADO IMA-B LP",
    cnpj: "10.740.739/0001-93",
    administrator_name: "Caixa Econômica Federal",
    administration_fee: 0.00,
    performance_fee: nil,
    benchmark_index: "IMA-B",
    enquadramento: 'Art. 7º,  Inciso III "a"'
  },
  {
    fund_name: "CAIXA BRASIL IPCA XVI FI RENDA FIXA CRÉDITO PRIVADO",
    cnpj: "21.918.896/0001-62",
    administrator_name: "Caixa Econômica Federal",
    administration_fee: 0.20,
    performance_fee: nil,
    benchmark_index: nil,
    enquadramento: 'Artigo 7º, Inciso V, "b"'
  },
  {
    fund_name: "CAIXA BRASIL INDEXA IBOVESPA FI AÇÕES",
    cnpj: "13.058.816/0001-18",
    administrator_name: "Caixa Econômica Federal",
    administration_fee: 0.50,
    performance_fee: nil,
    benchmark_index: nil, # IBOVESPA not in economic_indices
    enquadramento: 'Art. 8º, Inciso I'
  },
  {
    fund_name: "CAIXA BRASIL IBX-50 FI AÇÕES",
    cnpj: "03.737.217/0001-77",
    administrator_name: "Caixa Econômica Federal",
    administration_fee: 0.70,
    performance_fee: nil,
    benchmark_index: nil, # IBX-50 not in economic_indices
    enquadramento: 'Art. 8º, Inciso I'
  },
  {
    fund_name: "CAIXA IBOVESPA FIC AÇÕES",
    cnpj: "01.525.057/0001-77",
    administrator_name: "Caixa Econômica Federal",
    administration_fee: 2.00,
    performance_fee: nil,
    benchmark_index: nil,
    enquadramento: 'Art. 8º, Inciso I'
  },
  {
    fund_name: "CAIXA BRASIL ETF IBOVESPA FI AÇÕES",
    cnpj: "15.154.236/0001-50",
    administrator_name: "Caixa Econômica Federal",
    administration_fee: 0.50,
    performance_fee: nil,
    benchmark_index: nil,
    enquadramento: 'Art. 8º, Inciso I'
  },
  {
    fund_name: "CAIXA CONSTRUÇÃO CIVIL FI AÇÕES",
    cnpj: "10.551.375/0001-01",
    administrator_name: "Caixa Econômica Federal",
    administration_fee: 2.00,
    performance_fee: nil,
    benchmark_index: nil,
    enquadramento: 'Art. 8º, Inciso I'
  },
  {
    fund_name: "CAIXA INFRAESTRUTURA FI AÇÕES",
    cnpj: "10.551.382/0001-03",
    administrator_name: "Caixa Econômica Federal",
    administration_fee: 2.00,
    performance_fee: nil,
    benchmark_index: nil,
    enquadramento: 'Art. 8º, Inciso I'
  },
  {
    fund_name: "CAIXA EXPERT VINCI VALOR DIVIDENDOS RPPS FIC AÇÕES",
    cnpj: "15.154.441/0001-15",
    administrator_name: "Caixa Econômica Federal",
    administration_fee: 1.72,
    performance_fee: nil,
    benchmark_index: nil,
    enquadramento: 'Art. 8º, Inciso I'
  },
  {
    fund_name: "CAIXA PETROBRAS FI AÇÕES",
    cnpj: "03.914.671/0001-56",
    administrator_name: "Caixa Econômica Federal",
    administration_fee: 1.50,
    performance_fee: nil,
    benchmark_index: nil,
    enquadramento: 'Art. 8º, Inciso I'
  },
  {
    fund_name: "CAIXA VALE DO RIO DOCE FI AÇÕES",
    cnpj: "04.885.820/0001-69",
    administrator_name: "Caixa Econômica Federal",
    administration_fee: 2.00,
    performance_fee: nil,
    benchmark_index: nil,
    enquadramento: 'Art. 8º, Inciso I'
  },
  {
    fund_name: "CAIXA SUSTENTABILIDADE EMPRESARIAL ISE FI AÇÕES",
    cnpj: "08.070.838/0001-63",
    administrator_name: "Caixa Econômica Federal",
    administration_fee: 0.80,
    performance_fee: nil,
    benchmark_index: nil,
    enquadramento: 'Art. 8º, Inciso I'
  },
  {
    fund_name: "CAIXA DIVIDENDOS FI AÇÕES",
    cnpj: "05.900.798/0001-41",
    administrator_name: "Caixa Econômica Federal",
    administration_fee: 1.50,
    performance_fee: nil,
    benchmark_index: nil,
    enquadramento: 'Art. 8º, Inciso I'
  },
  {
    fund_name: "CAIXA CONSUMO FI AÇÕES",
    cnpj: "10.577.512/0001-79",
    administrator_name: "Caixa Econômica Federal",
    administration_fee: 1.60,
    performance_fee: nil,
    benchmark_index: nil,
    enquadramento: 'Art. 8º, Inciso I'
  },
  {
    fund_name: "CAIXA PETROBRAS PRÉ-SAL FI AÇÕES",
    cnpj: "11.060.594/0001-42",
    administrator_name: "Caixa Econômica Federal",
    administration_fee: 0.50,
    performance_fee: nil,
    benchmark_index: nil,
    enquadramento: 'Art. 8º, Inciso I'
  },
  {
    fund_name: "CAIXA EXPERT VINCI VALOR RPPS FIC AÇÕES",
    cnpj: "14.507.699/0001-95",
    administrator_name: "Caixa Econômica Federal",
    administration_fee: 1.72,
    performance_fee: nil,
    benchmark_index: nil,
    enquadramento: 'Art. 8º, Inciso I'
  },
  {
    fund_name: "CAIXA SMALL CAPS ATIVO FI AÇÕES",
    cnpj: "15.154.220/0001-47",
    administrator_name: "Caixa Econômica Federal",
    administration_fee: 1.50,
    performance_fee: nil,
    benchmark_index: nil,
    enquadramento: 'Art. 8º, Inciso I'
  },
  {
    fund_name: "CAIXA AÇÕES MULTIGESTOR FIC AÇÕES",
    cnpj: "30.068.224/0001-04",
    administrator_name: "Caixa Econômica Federal",
    administration_fee: 1.50,
    performance_fee: nil,
    benchmark_index: nil,
    enquadramento: 'Art. 8º, Inciso I'
  },
  {
    fund_name: "CAIXA BRASIL AÇÕES LIVRE QUANTITATIVO FIC AÇÕES",
    cnpj: "30.068.169/0001-44",
    administrator_name: "Caixa Econômica Federal",
    administration_fee: 2.00,
    performance_fee: nil,
    benchmark_index: nil,
    enquadramento: 'Art. 8º, Inciso I'
  },
  {
    fund_name: "CAIXA MASTER AÇÕES LIVRE QUANTITATIVO FI AÇÕES",
    cnpj: "30.036.209/0001-76",
    administrator_name: "Caixa Econômica Federal",
    administration_fee: 0.00,
    performance_fee: nil,
    benchmark_index: nil,
    enquadramento: 'Art. 8º, Inciso I'
  },
  {
    fund_name: "CAIXA EXPERT CLARITAS VALOR FIC AÇÕES",
    cnpj: "30.068.060/0001-07",
    administrator_name: "Caixa Econômica Federal",
    administration_fee: 1.25,
    performance_fee: nil,
    benchmark_index: nil,
    enquadramento: 'Art. 8º, Inciso I'
  },
  {
    fund_name: "CAIXA INDEXA SETOR FINANCEIRO FI AÇÕES",
    cnpj: "40.209.029/0001-00",
    administrator_name: "Caixa Econômica Federal",
    administration_fee: 0.80,
    performance_fee: nil,
    benchmark_index: nil,
    enquadramento: 'Art. 8º, Inciso I'
  },
  {
    fund_name: "CAIXA SEGURIDADE FI AÇÕES",
    cnpj: "30.068.049/0001-47",
    administrator_name: "Caixa Econômica Federal",
    administration_fee: 0.20,
    performance_fee: nil,
    benchmark_index: nil,
    enquadramento: 'Art. 8º, Inciso I'
  },
  {
    fund_name: "CAIXA JUROS E MOEDAS FI MULTIMERCADO LP",
    cnpj: "14.120.520/0001-42",
    administrator_name: "Caixa Econômica Federal",
    administration_fee: 0.70,
    performance_fee: 20.00,
    benchmark_index: "CDI",
    enquadramento: 'Art. 10º, Inciso I'
  },
  {
    fund_name: "CAIXA RV 30 FI MULTIMERCADO LP",
    cnpj: "03.737.188/0001-43",
    administrator_name: "Caixa Econômica Federal",
    administration_fee: 1.00,
    performance_fee: nil,
    benchmark_index: "CDI",
    enquadramento: 'Art. 10º, Inciso I'
  },
  {
    fund_name: "CAIXA ALOCAÇÃO MACRO FIC MULTIMERCADO LP",
    cnpj: "08.070.841/0001-87",
    administrator_name: "Caixa Econômica Federal",
    administration_fee: 0.50,
    performance_fee: nil,
    benchmark_index: "CDI",
    enquadramento: 'Art. 10º, Inciso I'
  },
  {
    fund_name: "CAIXA INDEXA BOLSA AMERICANA FI MULTIMERCADO LP",
    cnpj: "30.036.235/0001-02",
    administrator_name: "Caixa Econômica Federal",
    administration_fee: 0.80,
    performance_fee: nil,
    benchmark_index: nil,
    enquadramento: 'Art. 10º, Inciso I'
  },
  {
    fund_name: "CAIXA BRASIL ESTRATÉGIA LIVRE FIC MULTIMERCADO LP",
    cnpj: "34.660.276/0001-18",
    administrator_name: "Caixa Econômica Federal",
    administration_fee: 1.50,
    performance_fee: nil,
    benchmark_index: nil,
    enquadramento: 'Art. 10º, Inciso I'
  },
  {
    fund_name: "CAIXA MASTER ESTRATÉGIA LIVRE FI MULTIMERCADO LP",
    cnpj: "34.660.200/0001-92",
    administrator_name: "Caixa Econômica Federal",
    administration_fee: 0.00,
    performance_fee: nil,
    benchmark_index: nil,
    enquadramento: 'Art. 10º, Inciso I'
  },
  {
    fund_name: "CAIXA CAPITAL PROTEGIDO BOLSA DE VALORES III FIC MULTIMERCADO",
    cnpj: "18.007.358/0001-01",
    administrator_name: "Caixa Econômica Federal",
    administration_fee: 0.90,
    performance_fee: nil,
    benchmark_index: nil,
    enquadramento: 'Art. 10º, Inciso I'
  },
  {
    fund_name: "CAIXA MASTER CAPITAL PROTEGIDO BOLSA DE VALORES III FI MULTIMERCADO",
    cnpj: "22.791.190/0001-45",
    administrator_name: "Caixa Econômica Federal",
    administration_fee: 0.00,
    performance_fee: nil,
    benchmark_index: nil,
    enquadramento: 'Art. 10º, Inciso I'
  },
  {
    fund_name: "CAIXA HEDGE FIC MULTIMERCADO LP",
    cnpj: "30.068.135/0001-50",
    administrator_name: "Caixa Econômica Federal",
    administration_fee: 1.00,
    performance_fee: nil,
    benchmark_index: nil,
    enquadramento: 'Art. 10º, Inciso I'
  },
  {
    fund_name: "CAIXA MASTER HEDGE FI MULTIMERCADO LP",
    cnpj: "30.068.240/0001-99",
    administrator_name: "Caixa Econômica Federal",
    administration_fee: 0.00,
    performance_fee: nil,
    benchmark_index: nil,
    enquadramento: 'Art. 10º, Inciso I'
  },
  {
    fund_name: "CAIXA INDEXA SHORT DÓLAR FI MULTIMERCADO LP",
    cnpj: "29.157.511/0001-01",
    administrator_name: "Caixa Econômica Federal",
    administration_fee: 0.80,
    performance_fee: nil,
    benchmark_index: nil,
    enquadramento: 'Art. 10º, Inciso I'
  },
  {
    fund_name: "CAIXA RIO BRAVO FUNDO DE FII1",
    cnpj: "17.098.794/0001-70",
    administrator_name: "Caixa Econômica Federal",
    administration_fee: 1.20,
    performance_fee: nil,
    benchmark_index: nil,
    enquadramento: 'Art. 11º'
  },
  {
    fund_name: "CAIXA MULTIGESTOR GLOBAL EQUITIES INVESTIMENTO NO EXTERIOR FIC MULTIMERCADO",
    cnpj: "39.528.038/0001-77",
    administrator_name: "Caixa Econômica Federal",
    administration_fee: 1.00,
    performance_fee: nil,
    benchmark_index: nil,
    enquadramento: 'Art. 9º -  Inciso II'
  },
  {
    fund_name: "CAIXA INSTITUCIONAL FI AÇÕES BDR NÍVEL I",
    cnpj: "17.502.937/0001-68",
    administrator_name: "Caixa Econômica Federal",
    administration_fee: 0.70,
    performance_fee: nil,
    benchmark_index: nil,
    enquadramento: 'Art. 9º - Inciso III'
  },
  {
    fund_name: "CAIXA ESG FIC AÇÕES BDR NÍVEL I",
    cnpj: "43.760.251/0001-87",
    administrator_name: "Caixa Econômica Federal",
    administration_fee: 1.00,
    performance_fee: nil,
    benchmark_index: nil,
    enquadramento: 'Art. 9º - Inciso III'
  },
  {
    fund_name: "CAIXA MASTER ESG FI AÇÕES BDR NÍVEL I",
    cnpj: "42.195.992/0001-08",
    administrator_name: "Caixa Econômica Federal",
    administration_fee: 0.00,
    performance_fee: nil,
    benchmark_index: nil,
    enquadramento: 'Art. 9º - Inciso III'
  },
  # ---- BNB funds ----
  {
    fund_name: "BNB IMA-B FUNDO DE INVESTIMENTO RENDA FIXA",
    cnpj: "08.266.261/0001-60",
    administrator_name: "Banco do Nordeste do Brasil S/A",
    administration_fee: 0.20,
    performance_fee: nil,
    benchmark_index: "IMA-B",
    enquadramento: 'Art. 7º, Inciso I "b"'
  },
  {
    fund_name: "BNB INSTITUCIONAL FUNDO DE INVESTIMENTO RENDA FIXA",
    cnpj: "21.307.581/0001-89",
    administrator_name: "Banco do Nordeste do Brasil S/A",
    administration_fee: 0.35,
    performance_fee: nil,
    benchmark_index: "CDI",
    enquadramento: 'Art. 7º, Inciso I "b"'
  },
  {
    fund_name: "BNB FUNDO DE INVESTIMENTO MULTIMERCADO LONGO PRAZO",
    cnpj: "06.124.248/0001-40",
    administrator_name: "Banco do Nordeste do Brasil S/A",
    administration_fee: 0.20,
    performance_fee: nil,
    benchmark_index: "CDI",
    enquadramento: 'Art. 10º, Inciso I'
  },
  {
    fund_name: "BNB PLUS FUNDO DE INVESTIMENTO EM COTAS DE FUNDO DE INVESTIMENTO RENDA FIXA LONGO PRAZO",
    cnpj: "06.124.241/0001-29",
    administrator_name: "Banco do Nordeste do Brasil S/A",
    administration_fee: 0.50,
    performance_fee: nil,
    benchmark_index: "CDI",
    enquadramento: 'Art. 7º,  Inciso III "a"'
  },
  {
    fund_name: "BNB SELEÇÃO FUNDO DE INVESTIMENTO AÇÕES",
    cnpj: "63.375.216/0001-51",
    administrator_name: "Banco do Nordeste do Brasil S/A",
    administration_fee: 2.00,
    performance_fee: nil,
    benchmark_index: nil,
    enquadramento: 'Art. 8º, Inciso I'
  },
  {
    fund_name: "BNB SOBERANO FUNDO DE INVESTIMENTO RENDA FIXA",
    cnpj: "30.568.193/0001-42",
    administrator_name: "Banco do Nordeste do Brasil S/A",
    administration_fee: 0.20,
    performance_fee: nil,
    benchmark_index: "CDI",
    enquadramento: 'Art. 7º, Inciso I "b"'
  },
  {
    fund_name: "BNB IRF-M 1 TÍTULOS PÚBLICOS FUNDO DE INVESTIMENTO RENDA FIXA",
    cnpj: "35.816.816/0001-72",
    administrator_name: "Banco do Nordeste do Brasil S/A",
    administration_fee: 0.20,
    performance_fee: nil,
    benchmark_index: "IRF M 1",
    enquadramento: 'Art. 7º, Inciso I "b"'
  },
  {
    fund_name: "BNB CDB 100,50%",
    cnpj: "62.318.407/0001-19",
    administrator_name: "Banco do Nordeste do Brasil S/A",
    administration_fee: 0.00,
    performance_fee: nil,
    benchmark_index: "CDI",
    enquadramento: 'Art. 7º, Inciso IV'
  },
  # ---- Eletrobras fund ----
  {
    fund_name: "FUNDO DE INVESTIMENTO EM AÇÕES CAIXA ELETROBRAS",
    cnpj: "45.443.475/0001-90",
    administrator_name: "Caixa Econômica Federal",
    administration_fee: 0.45,
    performance_fee: nil,
    benchmark_index: nil,
    enquadramento: 'Art. 8º, Inciso I'
  },
  # ---- BB funds ----
  {
    fund_name: "BB PREVIDENCIÁRIO RENDA FIXA IMA-B 5 LONGO PRAZO FIC DE FI",
    cnpj: "03.543.447/0001-03",
    administrator_name: "BB GESTÃO DE RECURSOS DTVM S/A",
    administration_fee: 0.20,
    performance_fee: nil,
    benchmark_index: "IMA-B5",
    enquadramento: 'Art. 7º, Inciso I "b"'
  },
  {
    fund_name: "BB INSTITUCIONAL FUNDO DE INVESTIMENTO RENDA FIXA",
    cnpj: "02.296.928/0001-90",
    administrator_name: "BB GESTÃO DE RECURSOS DTVM S/A",
    administration_fee: 0.20,
    performance_fee: nil,
    benchmark_index: "CDI",
    enquadramento: 'Art. 7º,  Inciso III "a"'
  },
  {
    fund_name: "BB PREVIDENCIÁRIO RENDA FIXA IMA-B FI",
    cnpj: "07.861.554/0001-22",
    administrator_name: "BB GESTÃO DE RECURSOS DTVM S/A",
    administration_fee: 0.60,
    performance_fee: nil,
    benchmark_index: "IMA-B",
    enquadramento: 'Art. 7º,  Inciso III "a"'
  },
  {
    fund_name: "BB PREVIDENCIÁRIO RENDA FIXA IRF-M TÍTULOS PÚBLICOS FI",
    cnpj: "07.111.384/0001-69",
    administrator_name: "BB GESTÃO DE RECURSOS DTVM S/A",
    administration_fee: 0.20,
    performance_fee: nil,
    benchmark_index: "IRF M",
    enquadramento: 'Art. 7º, Inciso I "b"'
  },
  {
    fund_name: "BB PREVIDENCIÁRIO RENDA FIXA IMA-B TÍTULOS PÚBLICOS FI",
    cnpj: "07.442.078/0001-05",
    administrator_name: "BB GESTÃO DE RECURSOS DTVM S/A",
    administration_fee: 0.20,
    performance_fee: nil,
    benchmark_index: "IMA-B",
    enquadramento: 'Art. 7º, Inciso I "b"'
  },
  {
    fund_name: "BB Previd TP IPCA",
    cnpj: "15.486.093/0001-83",
    administrator_name: "BB GESTÃO DE RECURSOS DTVM S/A",
    administration_fee: 0.15,
    performance_fee: nil,
    benchmark_index: "IPCA",
    enquadramento: 'Art. 7º, Inciso I "b"'
  },
  {
    fund_name: "BB Previd RF TP IPCA I FI",
    cnpj: "19.303.793/0001-46",
    administrator_name: "BB GESTÃO DE RECURSOS DTVM S/A",
    administration_fee: 0.15,
    performance_fee: nil,
    benchmark_index: "IPCA",
    enquadramento: 'Art. 7º, Inciso I "b"'
  },
  {
    fund_name: "BB COMERCIAL 17 LP FIC DE FI RF",
    cnpj: "04.857.834/0001-79",
    administrator_name: "BB GESTÃO DE RECURSOS DTVM S/A",
    administration_fee: 0.30,
    performance_fee: nil,
    benchmark_index: "CDI",
    enquadramento: 'Art. 7º,  Inciso III "a"'
  },
  {
    fund_name: "BB Previd RF TP IPCA III FI",
    cnpj: "19.303.795/0001-35",
    administrator_name: "BB GESTÃO DE RECURSOS DTVM S/A",
    administration_fee: 0.20,
    performance_fee: nil,
    benchmark_index: "IPCA",
    enquadramento: 'Art. 7º, Inciso I "b"'
  },
  {
    fund_name: "BB Previd RF TP IPCA V FI",
    cnpj: "19.515.016/0001-65",
    administrator_name: "BB GESTÃO DE RECURSOS DTVM S/A",
    administration_fee: 0.20,
    performance_fee: nil,
    benchmark_index: "IPCA",
    enquadramento: 'Art. 7º, Inciso I "b"'
  },
  {
    fund_name: "BB Previd RF TP IPCA VI FI",
    cnpj: "19.523.306/0001-50",
    administrator_name: "BB GESTÃO DE RECURSOS DTVM S/A",
    administration_fee: 0.20,
    performance_fee: nil,
    benchmark_index: "IPCA",
    enquadramento: 'Art. 7º, Inciso I "b"'
  },
  {
    fund_name: "BB PREVIDENCIÁRIO RENDA FIXA IRF-M1 TÍTULOS PÚBLICOS FIC DE FI",
    cnpj: "11.328.882/0001-35",
    administrator_name: "BB GESTÃO DE RECURSOS DTVM S/A",
    administration_fee: 0.30,
    performance_fee: nil,
    benchmark_index: "IRF M 1",
    enquadramento: 'Art. 7º, Inciso I "b"'
  },
  {
    fund_name: "BB PREVIDENCIÁRIO RENDA FIXA IMA-B5+ TÍTULOS PÚBLICOS FI",
    cnpj: "13.327.340/0001-73",
    administrator_name: "BB GESTÃO DE RECURSOS DTVM S/A",
    administration_fee: 0.20,
    performance_fee: nil,
    benchmark_index: nil, # IMA-B 5+ not in economic_indices
    enquadramento: 'Art. 7º, Inciso I "b"'
  },
  {
    fund_name: "BB PREVIDENCIÁRIO RENDA FIXA IDKA2 TÍTULOS PÚBLICOS FI",
    cnpj: "13.322.205/0001-35",
    administrator_name: "BB GESTÃO DE RECURSOS DTVM S/A",
    administration_fee: 0.20,
    performance_fee: nil,
    benchmark_index: "IDKA IPCA 2A",
    enquadramento: 'Art. 7º, Inciso I "b"'
  },
  {
    fund_name: "BB PREVIDENCIÁRIO FLUXO RENDA FIXA SIMPLES FIC FI",
    cnpj: "13.077.415/0001-05",
    administrator_name: "BB GESTÃO DE RECURSOS DTVM S/A",
    administration_fee: 1.00,
    performance_fee: nil,
    benchmark_index: "CDI",
    enquadramento: 'Art. 7º,  Inciso III "a"'
  },
  {
    fund_name: "BB PREVIDENCIÁRIO RENDA FIXA PERFIL FIC DE FI",
    cnpj: "13.077.418/0001-49",
    administrator_name: "BB GESTÃO DE RECURSOS DTVM S/A",
    administration_fee: 0.30,
    performance_fee: nil,
    benchmark_index: "CDI",
    enquadramento: 'Art. 7º,  Inciso III "a"'
  },
  {
    fund_name: "BB PREVIDENCIÁRIO RENDA FIXA IMA GERAL EX-C TÍTULO PÚBLICO FI",
    cnpj: "14.964.240/0001-10",
    administrator_name: "BB GESTÃO DE RECURSOS DTVM S/A",
    administration_fee: 0.20,
    performance_fee: nil,
    benchmark_index: nil, # IMA (general ex-C) not in economic_indices
    enquadramento: 'Art. 7º, Inciso I "b"'
  },
  {
    fund_name: "BB Previd RF Tit Pub VII FI",
    cnpj: "19.523.305/0001-06",
    administrator_name: "BB GESTÃO DE RECURSOS DTVM S/A",
    administration_fee: 0.20,
    performance_fee: nil,
    benchmark_index: "IMA-B",
    enquadramento: 'Art. 7º, Inciso I "b"'
  },
  {
    fund_name: "BB Previd RF Tit Publ X FI",
    cnpj: "20.734.931/0001-20",
    administrator_name: "BB GESTÃO DE RECURSOS DTVM S/A",
    administration_fee: 0.20,
    performance_fee: nil,
    benchmark_index: "IPCA",
    enquadramento: 'Art. 7º, Inciso I "b"'
  },
  {
    fund_name: "BB Previd RF Tit Pub XI FI",
    cnpj: "24.117.278/0001-01",
    administrator_name: "BB GESTÃO DE RECURSOS DTVM S/A",
    administration_fee: 0.20,
    performance_fee: nil,
    benchmark_index: nil, # IDkA IPCA 5 ANOS not in economic_indices
    enquadramento: 'Art. 7º, Inciso I "b"'
  },
  {
    fund_name: "BB PREVIDENCIÁRIO RF ALOCAÇÃO ATIVA FIC DE FI",
    cnpj: "25.078.994/0001-90",
    administrator_name: "BB GESTÃO DE RECURSOS DTVM S/A",
    administration_fee: 0.50,
    performance_fee: nil,
    benchmark_index: nil, # IMA-GERAL ex-C not in economic_indices
    enquadramento: 'Art. 7º, Inciso I "b"'
  },
  {
    fund_name: "BB PREVIDENCIÁRIO RENDA FIXA IRF-M1+ TÍTULOS PÚBLICOS FI",
    cnpj: "32.161.826/0001-29",
    administrator_name: "BB GESTÃO DE RECURSOS DTVM S/A",
    administration_fee: 0.30,
    performance_fee: nil,
    benchmark_index: nil, # IRF M 1+ not in economic_indices
    enquadramento: 'Art. 7º, Inciso I "b"'
  },
  {
    fund_name: "BB PREVIDENCIÁRIO RF ALOCAÇÃO ATIVA RETORNO TOTAL",
    cnpj: "35.292.588/0001-89",
    administrator_name: "BB GESTÃO DE RECURSOS DTVM S/A",
    administration_fee: 0.50,
    performance_fee: nil,
    benchmark_index: "IPCA",
    enquadramento: 'Art. 7º,  Inciso III "a"'
  },
  {
    fund_name: "BB RENDA FIXA CURTO PRAZO AUTOMÁTICO SETOR PUBLICO FIC FI",
    cnpj: "04.288.966/0001-27",
    administrator_name: "BB GESTÃO DE RECURSOS DTVM S/A",
    administration_fee: 1.75,
    performance_fee: nil,
    benchmark_index: "CDI",
    enquadramento: 'Art. 7º,  Inciso III "a"'
  },
  {
    fund_name: "FIC CAIXA BRASIL IDKA PRE 2A RF LP",
    cnpj: "45.163.710/0001-70",
    administrator_name: "Caixa Econômica Federal",
    administration_fee: 0.20,
    performance_fee: nil,
    benchmark_index: "IDKA PRE 2A",
    enquadramento: 'Art. 7º, Inciso I "b"'
  }
]

# ---------------------------------------------------------------------------
# Seed execution
# ---------------------------------------------------------------------------
puts "Seeding InvestmentFunds..."

funds.each do |data|
  article_id = ENQUADRAMENTO_MAP[data[:enquadramento]]
  benchmark  = BENCHMARK_MAP[data[:benchmark_index]] if data[:benchmark_index]

  fund = InvestmentFund.find_or_initialize_by(cnpj: data[:cnpj])
  fund.assign_attributes(
    fund_name:         data[:fund_name],
    administrator_name: data[:administrator_name],
    administration_fee: data[:administration_fee],
    performance_fee:   data[:performance_fee],
    benchmark_index:   benchmark,
    originator_fund:   nil
  )

  if fund.save
    if article_id
      InvestmentFundArticle.find_or_create_by!(
        investment_fund_id:   fund.id,
        normative_article_id: article_id
      )
    end
    puts "  ✓ #{fund.fund_name}"
  else
    puts "  ✗ #{fund.fund_name} — #{fund.errors.full_messages.join(', ')}"
  end
end

puts "\nDone! #{funds.size} funds processed."
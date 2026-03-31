# === db/seeds.rb
#
# Description:: Este arquivo contém as instruções para popular o banco de dados com
#               os registros iniciais de fundos de investimento e seus índices.
#               Ele garante que o sistema possua uma base de dados consistente e
#               segura para operar em ambiente de produção sem duplicidade.
#
# Usage:: - *O que* - Este script representa a configuração inicial de dados.
#         - *Como* - Ele processa uma lista de dados e cria registros de forma segura.
#         - *Por que* - É necessário para fornecer à aplicação dados reais de fundos.
#
# Attributes:: - *@funds_data* [Array] - Uma coleção de detalhes dos fundos a processar.
#
# View:: - +InvestmentFund+
#
# Notes:: Este script utiliza +find_or_create_by!+ para evitar registros duplicados
#         com base no identificador único CNPJ e abreviações de índices.
#

# =============================================================
# DATA DEFINITION
# =============================================================

# Explanation:: Esta constante armazena os dados brutos que serão utilizados
#               durante o processo de semeadura do banco de dados.
#               Ela contém o mapeamento específico para cada fundo necessário.
FUNDS_DATA = [
  {
    "Fundo": "CAIXA BRASIL TÍTULOS PÚBLICOS FI RENDA FIXA LP",
    "Enquadramento 5.272/25": "Art. 7º, Inciso I ",
    "CNPJ do Fundo": "05.164.356/0001-84",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "0.20%",
    "Índice de Referência": "CDI",
    "Taxa de Performance": "-"
  },
  {
    "Fundo": "CAIXA RS TÍTULOS PÚBLICOS FI RENDA FIXA LP",
    "Enquadramento 5.272/25": "Art. 7º, Inciso I ",
    "CNPJ do Fundo": "05.164.364/0001-20",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "0.20%",
    "Taxa de Performance": "-"
  },
  {
    "Fundo": "CAIXA ALIANÇA TÍTULOS PÚBLICOS FI RENDA FIXA",
    "Enquadramento 5.272/25": "Art. 7º, Inciso I ",
    "CNPJ do Fundo": "05.164.358/0001-73",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "0.20%",
    "Taxa de Performance": "-"
  },
  {
    "Fundo": "CAIXA BRASIL DISPONIBILIDADES FIC RENDA FIXA",
    "Enquadramento 5.272/25": "Art. 7º, Inciso I ",
    "CNPJ do Fundo": "14.508.643/0001-55",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "0.80%",
    "Taxa de Performance": "-"
  },
  {
    "Fundo": "CAIXA MASTER LIQUIDEZ FI RENDA FIXA CURTO PRAZO",
    "Enquadramento 5.272/25": "Art. 7º, Inciso I ",
    "CNPJ do Fundo": "04.150.666/0001-87",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "0.00%",
    "Taxa de Performance": "-"
  },
  {
    "Fundo": "CAIXA BRASIL ESPECIAL 2028 TÍTULOS PÚBLICOS RESP LIMITADA FIF RENDA FIXA",
    "Enquadramento 5.272/25": "Art. 7º, Inciso I ",
    "CNPJ do Fundo": "56.209.124/0001-36",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "0.06%",
    "Índice de Referência": "IPCA",
    "Taxa de Performance": "-"
  },
  {
    "Fundo": "CAIXA BRASIL ESPECIAL 2027 TÍTULOS PÚBLICOS RESP LIMITADA FIF RENDA FIXA",
    "Enquadramento 5.272/25": "Art. 7º, Inciso I ",
    "CNPJ do Fundo": "56.208.863/0001-03",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "0.06%",
    "Índice de Referência": "IPCA",
    "Taxa de Performance": "-"
  },
  {
    "Fundo": "CAIXA BRASIL ESPECIAL 2030 TÍTULOS PÚBLICOS RESP LIMITADA FIF RENDA FIXA",
    "Enquadramento 5.272/25": "Art. 7º, Inciso I ",
    "CNPJ do Fundo": "56.209.467/0001-09",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "0.06%",
    "Índice de Referência": "IPCA",
    "Taxa de Performance": "-"
  },
  {
    "Fundo": "CAIXA BRASIL IMA-B TÍTULOS PÚBLICOS FI RENDA FIXA LP",
    "Enquadramento 5.272/25": "Art. 7º, Inciso I ",
    "CNPJ do Fundo": "10.740.658/0001-93",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "0.20%",
    "Índice de Referência": "IMA-B",
    "Taxa de Performance": "-"
  },
  {
    "Fundo": "CAIXA BRASIL IMA-GERAL TÍTULOS PÚBLICOS FI RF LP",
    "Enquadramento 5.272/25": "Art. 7º, Inciso I ",
    "CNPJ do Fundo": "11.061.217/0001-28",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "0.20%",
    "Índice de Referência": "IMA GERAL",
    "Taxa de Performance": "-"
  },
  {
    "Fundo": "CAIXA BRASIL IMA-B 5 TÍTULOS PÚBLICOS FI RENDA FIXA LP",
    "Enquadramento 5.272/25": "Art. 7º, Inciso I ",
    "CNPJ do Fundo": "11.060.913/0001-10",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "0.20%",
    "Índice de Referência": "IMA-B 5",
    "Taxa de Performance": "-"
  },
  {
    "Fundo": "CAIXA BRASIL IRF-M 1 TÍTULOS PÚBLICOS FI RENDA FIXA",
    "Enquadramento 5.272/25": "Art. 7º, Inciso I ",
    "CNPJ do Fundo": "10.740.670/0001-06",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "0.20%",
    "Índice de Referência": "IRF-M 1",
    "Taxa de Performance": "-"
  },
  {
    "Fundo": "CAIXA BRASIL IMA-B 5+ TÍTULOS PÚBLICOS FI RENDA FIXA LP",
    "Enquadramento 5.272/25": "Art. 7º, Inciso I ",
    "CNPJ do Fundo": "10.577.503/0001-88",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "0.20%",
    "Índice de Referência": "IMA-B 5+",
    "Taxa de Performance": "-"
  },
  {
    "Fundo": "CAIXA BRASIL IRF-M 1+ TÍTULOS PÚBLICOS FI RENDA FIXA LP",
    "Enquadramento 5.272/25": "Art. 7º, Inciso I ",
    "CNPJ do Fundo": "10.577.519/0001-90",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "0.20%",
    "Índice de Referência": "IRF-M 1+",
    "Taxa de Performance": "-"
  },
  {
    "Fundo": "CAIXA BRASIL IDKA IPCA 2A T.P RENDA FIXA LP",
    "Enquadramento 5.272/25": "Art. 7º, Inciso I ",
    "CNPJ do Fundo": "14.386.926/0001-71",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "0.20%",
    "Índice de Referência": "IDKA IPCA 2A",
    "Taxa de Performance": "-"
  },
  {
    "Fundo": "CAIXA BRASIL IRF-M TÍTULOS PÚBLICOS FI RENDA FIXA LP",
    "Enquadramento 5.272/25": "Art. 7º, Inciso I ",
    "CNPJ do Fundo": "14.508.605/0001-00",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "0.20%",
    "Índice de Referência": "IRF-M",
    "Taxa de Performance": "-"
  },
  {
    "Fundo": "CAIXA BRASIL GESTÃO ESTRATÉGICA FIC RENDA FIXA",
    "Enquadramento 5.272/25": "Art. 7º, Inciso I ",
    "CNPJ do Fundo": "23.215.097/0001-55",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "0.40%",
    "Índice de Referência": "IPCA",
    "Taxa de Performance": "-"
  },
  {
    "Fundo": "CAIXA BRASIL RESP LIMITADA FIF RENDA FIXA REFERENCIADO DI LP",
    "Enquadramento 5.272/25": "Art. 7º,  Inciso V",
    "CNPJ do Fundo": "03.737.206/0001-97",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "0.20%",
    "Índice de Referência": "CDI",
    "Taxa de Performance": "-"
  },
  {
    "Fundo": "CAIXA BRASIL MATRIZ RESP LIMITADA FIF RENDA FIXA",
    "Enquadramento 5.272/25": "Art. 7º,  Inciso V",
    "CNPJ do Fundo": "23.215.008/0001-70",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "0.20%",
    "Índice de Referência": "CDI",
    "Taxa de Performance": "-"
  },
  {
    "Fundo": "CAIXA BRASIL ATIVA RESP LIMITADA FIF CIC RENDA FIXA LP",
    "Enquadramento 5.272/25": "Art. 7º,  Inciso V",
    "CNPJ do Fundo": "35.536.532/0001-22",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "0.40%",
    "Índice de Referência": "IPCA",
    "Taxa de Performance": "-"
  },
  {
    "Fundo": "CAIXA MASTER ATIVA FI RENDA FIXA LP",
    "Enquadramento 5.272/25": "Art. 7º,  Inciso V",
    "CNPJ do Fundo": "35.536.520/0001-06",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "0.00%",
    "Taxa de Performance": "-"
  },
  {
    "Fundo": "CAIXA NOVO BRASIL FIC RENDA FIXA REFERENCIADO IMA-B LP",
    "Enquadramento 5.272/25": "Art. 7º,  Inciso V",
    "CNPJ do Fundo": "10.646.895/0001-90",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "0.20%",
    "Índice de Referência": "IMA-B",
    "Taxa de Performance": "-"
  },
  {
    "Fundo": "CAIXA MASTER BRASIL FI RENDA FIXA REFERENCIADO IMA-B LP",
    "Enquadramento 5.272/25": "Art. 7º,  Inciso V",
    "CNPJ do Fundo": "10.740.739/0001-93",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "0.00%",
    "Índice de Referência": "IMA-B",
    "Taxa de Performance": "-"
  },
  {
    "Fundo": "CAIXA BRASIL IPCA XVI RESP LIMITADA FIF RENDA FIXA CRÉDITO PRIVADO",
    "Enquadramento 5.272/25": "Artigo 7º, Inciso VII",
    "CNPJ do Fundo": "21.918.896/0001-62",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "0.20%",
    "Índice de Referência": "-",
    "Taxa de Performance": "-"
  },
  {
    "Fundo": "CAIXA BRASIL INDEXA IBOVESPA RESP LIMITADA FIF AÇÕES",
    "Enquadramento 5.272/25": "Art. 8º, Inciso I ",
    "CNPJ do Fundo": "13.058.816/0001-18",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "0.50%",
    "Índice de Referência": "IBOVESPA",
    "Taxa de Performance": "-"
  },
  {
    "Fundo": "CAIXA BRASIL IBX-50 RESP LIMITADA FIF AÇÕES",
    "Enquadramento 5.272/25": "Art. 8º, Inciso I ",
    "CNPJ do Fundo": "03.737.217/0001-77",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "0.70%",
    "Índice de Referência": "IBX-50",
    "Taxa de Performance": "-"
  },
  {
    "Fundo": "CAIXA IBOVESPA RESP LIMITADA FIF CIC AÇÕES",
    "Enquadramento 5.272/25": "Art. 8º, Inciso I ",
    "CNPJ do Fundo": "01.525.057/0001-77",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "2.00%",
    "Índice de Referência": "IBOVESPA",
    "Taxa de Performance": "-"
  },
  {
    "Fundo": "CAIXA BRASIL ETF IBOVESPA RESP LIMITADA FIF AÇÕES",
    "Enquadramento 5.272/25": "Art. 8º, Inciso I ",
    "CNPJ do Fundo": "15.154.236/0001-50",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "0.50%",
    "Índice de Referência": "IBOVESPA"
  },
  {
    "Fundo": "CAIXA CONSTRUÇÃO CIVIL RESP LIMITADA FIF AÇÕES",
    "Enquadramento 5.272/25": "Art. 8º, Inciso I ",
    "CNPJ do Fundo": "10.551.375/0001-01",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "2.00%",
    "Índice de Referência": "IMOB",
    "Taxa de Performance": "-"
  },
  {
    "Fundo": "CAIXA INFRAESTRUTURA RESP LIMITADA FIF AÇÕES",
    "Enquadramento 5.272/25": "Art. 8º, Inciso I ",
    "CNPJ do Fundo": "10.551.382/0001-03",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "2.00%",
    "Índice de Referência": "INFRA",
    "Taxa de Performance": "-"
  },
  {
    "Fundo": "CAIXA EXPERT VINCI VALOR DIVIDENDOS RPPS RESP LIMITADA FIF CIC AÇÕES",
    "Enquadramento 5.272/25": "Art. 8º, Inciso I ",
    "CNPJ do Fundo": "15.154.441/0001-15",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "1.72%",
    "Índice de Referência": "IDIV",
    "Taxa de Performance": "-"
  },
  {
    "Fundo": "CAIXA PETROBRAS RESP LIMITADA FIF AÇÕES",
    "Enquadramento 5.272/25": "Art. 8º, Inciso I ",
    "CNPJ do Fundo": "03.914.671/0001-56",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "1.50%",
    "Índice de Referência": "PETRO",
    "Taxa de Performance": "-"
  },
  {
    "Fundo": "CAIXA VALE DO RIO DOCE RESP LIMITADA FIF AÇÕES",
    "Enquadramento 5.272/25": "Art. 8º, Inciso I ",
    "CNPJ do Fundo": "04.885.820/0001-69",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "2.00%",
    "Índice de Referência": "VALE",
    "Taxa de Performance": "-"
  },
  {
    "Fundo": "CAIXA SUSTENTABILIDADE EMPRESARIAL ISE IS RESP LIMITADA FIF AÇÕES",
    "Enquadramento 5.272/25": "Art. 8º, Inciso I ",
    "CNPJ do Fundo": "08.070.838/0001-63",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "0.80%",
    "Índice de Referência": "ISE",
    "Taxa de Performance": "-"
  },
  {
    "Fundo": "CAIXA DIVIDENDOS RESP LIMITADA FIF AÇÕES",
    "Enquadramento 5.272/25": "Art. 8º, Inciso I ",
    "CNPJ do Fundo": "05.900.798/0001-41",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "1.50%",
    "Índice de Referência": "IDIV",
    "Taxa de Performance": "-"
  },
  {
    "Fundo": "CAIXA CONSUMO RESP LIMITADA FIF AÇÕES",
    "Enquadramento 5.272/25": "Art. 8º, Inciso I ",
    "CNPJ do Fundo": "10.577.512/0001-79",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "1.60%",
    "Índice de Referência": "ICON",
    "Taxa de Performance": "-"
  },
  {
    "Fundo": "CAIXA PETROBRAS PRÉ SAL RESP LIMITADA FIF AÇÕES 03.914.671/0001-56",
    "Enquadramento 5.272/25": "Art. 8º, Inciso I ",
    "CNPJ do Fundo": "11.060.594/0001-42",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "0.50%",
    "Índice de Referência": "PETRO",
    "Taxa de Performance": "-"
  },
  {
    "Fundo": "CAIXA EXPERT VINCI VALOR RPPS RESP LIMITADA FIF CIC AÇÕES",
    "Enquadramento 5.272/25": "Art. 8º, Inciso I ",
    "CNPJ do Fundo": "14.507.699/0001-95",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "1.72%",
    "Índice de Referência": "-",
    "Taxa de Performance": "-"
  },
  {
    "Fundo": "CAIXA SMALL CAPS ATIVO RESP LIMITADA FIF AÇÕES",
    "Enquadramento 5.272/25": "Art. 8º, Inciso I ",
    "CNPJ do Fundo": "15.154.220/0001-47",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "1.50%",
    "Índice de Referência": "SMLL",
    "Taxa de Performance": "-"
  },
  {
    "Fundo": "CAIXA AÇÕES MULTIGESTOR RESP LIMITADA FIF CIC AÇÕES",
    "Enquadramento 5.272/25": "Art. 8º, Inciso I ",
    "CNPJ do Fundo": "30.068.224/0001-04",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "1.50%",
    "Índice de Referência": "IBOVESPA",
    "Taxa de Performance": "-"
  },
  {
    "Fundo": "CAIXA ATENA BRASIL AÇÕES LIVRE QUANT RESP LIMITADA FIF CIC AÇÕES",
    "Enquadramento 5.272/25": "Art. 8º, Inciso I ",
    "CNPJ do Fundo": "30.068.169/0001-44",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "2.00%",
    "Índice de Referência": "-",
    "Taxa de Performance": "-"
  },
  {
    "Fundo": "CAIXA MASTER AÇÕES LIVRE QUANTITATIVO Fundo de Ações em Geral",
    "Enquadramento 5.272/25": "Art. 8º, Inciso I ",
    "CNPJ do Fundo": "30.036.209/0001-76",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "0.00%",
    "Índice de Referência": "-",
    "Taxa de Performance": "-"
  },
  {
    "Fundo": "CAIXA EXPERT CLARITAS VALOR RESP LIMITADA FIF CIC AÇÕES",
    "Enquadramento 5.272/25": "Art. 8º, Inciso I ",
    "CNPJ do Fundo": "30.068.060/0001-07",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "1.25%",
    "Índice de Referência": "-",
    "Taxa de Performance": "-"
  },
  {
    "Fundo": "CAIXA INDEXA SETOR FINANCEIRO RESP LIMITADA FIF AÇÕES",
    "Enquadramento 5.272/25": "Art. 8º, Inciso I ",
    "CNPJ do Fundo": "40.209.029/0001-00",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "0.80%",
    "Índice de Referência": "-",
    "Taxa de Performance": "-"
  },
  {
    "Fundo": "CAIXA SEGURIDADE RESP LIMITADA FIF AÇÕES",
    "Enquadramento 5.272/25": "Art. 8º, Inciso I ",
    "CNPJ do Fundo": "30.068.049/0001-47",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "0.20%",
    "Índice de Referência": "-",
    "Taxa de Performance": "-"
  },
  {
    "Fundo": "CAIXA JUROS E MOEDAS RESP LIMITADA FIF CIC MULTIMERCADO LP",
    "Enquadramento 5.272/25": "Art. 10º, Inciso I",
    "CNPJ do Fundo": "14.120.520/0001-42",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "0.70%",
    "Índice de Referência": "CDI",
    "Taxa de Performance": "20%"
  },
  {
    "Fundo": "CAIXA RV 30 RESP LIMITADA FIF MULTIMERCADO LP",
    "Enquadramento 5.272/25": "Art. 10º, Inciso I",
    "CNPJ do Fundo": "03.737.188/0001-43",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "1.00%",
    "Índice de Referência": "CDI",
    "Taxa de Performance": "-"
  },
  {
    "Fundo": "CAIXA ALOCAÇÃO MACRO RESP LIMITADA FIF CIC MULTIMERCADO LP",
    "Enquadramento 5.272/25": "Art. 10º, Inciso I",
    "CNPJ do Fundo": "08.070.841/0001-87",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "0.50%",
    "Índice de Referência": "CDI",
    "Taxa de Performance": "-"
  },
  {
    "Fundo": "CAIXA INDEXA BOLSA AMERICANA RESP LIMITADA FIF MULTIMERCADO LP",
    "Enquadramento 5.272/25": "Art. 10º, Inciso I",
    "CNPJ do Fundo": "30.036.235/0001-02",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "0.80%",
    "Índice de Referência": "-",
    "Taxa de Performance": "-"
  },
  {
    "Fundo": "CAIXA BRASIL ESTRATÉGIA LIVRE RESP LIMITADA FIF CIC MULTIMERCADO LP",
    "Enquadramento 5.272/25": "Art. 10º, Inciso I",
    "CNPJ do Fundo": "34.660.276/0001-18",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "1.50%",
    "Índice de Referência": "-",
    "Taxa de Performance": "-"
  },
  {
    "Fundo": "CAIXA MASTER ESTRATÉGIA LIVRE FI FI Multimercado Aberto LP",
    "Enquadramento 5.272/25": "Art. 10º, Inciso I",
    "CNPJ do Fundo": "34.660.200/0001-92",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "0.00%",
    "Índice de Referência": "-",
    "Taxa de Performance": "-"
  },
  {
    "Fundo": "CAIXA CAPITAL PROTEGIDO BOLSA DE VALORES III FIC FI Multimercado Aberto",
    "Enquadramento 5.272/25": "Art. 10º, Inciso I",
    "CNPJ do Fundo": "18.007.358/0001-01",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "0.90%",
    "Índice de Referência": "IBOVESPA",
    "Taxa de Performance": "-"
  },
  {
    "Fundo": "CAIXA MASTER CAPITAL PROTEGIDO BOLSA DE VALORES III FI FI Multimercado Aberto",
    "Enquadramento 5.272/25": "Art. 10º, Inciso I",
    "CNPJ do Fundo": "22.791.190/0001-45",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "0.00%",
    "Índice de Referência": "IBOVESPA",
    "Taxa de Performance": "-"
  },
  {
    "Fundo": "CAIXA HEDGE RESP LIMITADA FIF CIC MULTIMERCADO LP",
    "Enquadramento 5.272/25": "Art. 10º, Inciso I",
    "CNPJ do Fundo": "30.068.135/0001-50",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "1.00%",
    "Índice de Referência": "-",
    "Taxa de Performance": "-"
  },
  {
    "Fundo": "CAIXA MASTER HEDGE FI FI Multimercado Aberto LP",
    "Enquadramento 5.272/25": "Art. 10º, Inciso I",
    "CNPJ do Fundo": "30.068.240/0001-99",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "0.00%",
    "Índice de Referência": "-",
    "Taxa de Performance": "-"
  },
  {
    "Fundo": "CAIXA INDEXA SHORT DÓLAR RESP LIMITADA FIF MULTIMERCADO LP",
    "Enquadramento 5.272/25": "Art. 10º, Inciso I",
    "CNPJ do Fundo": "29.157.511/0001-01",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "0.80%",
    "Índice de Referência": "-",
    "Taxa de Performance": "-"
  },
  {
    "Fundo": "CAIXA RIO BRAVO FUNDO DE FII1",
    "Enquadramento 5.272/25": "Art. 11º",
    "CNPJ do Fundo": "17.098.794/0001-70",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "1.20%",
    "Índice de Referência": "IFIX",
    "Taxa de Performance": "-"
  },
  {
    "Fundo": "CAIXA MULTIGESTOR GLOBAL EQUITIES INV EXTERIOR RESP LIMITADA FIF CIC MULTIMERCADO",
    "Enquadramento 5.272/25": "Art. 9º -  Inciso II",
    "CNPJ do Fundo": "39.528.038/0001-77",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "1.00%",
    "Índice de Referência": "-",
    "Taxa de Performance": "-"
  },
  {
    "Fundo": "CAIXA INSTITUCIONAL RESP LIMITADA FIF AÇÕES BDR NÍVEL I",
    "Enquadramento 5.272/25": "Art. 8º - Inciso III",
    "CNPJ do Fundo": "17.502.937/0001-68",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "0.70%",
    "Índice de Referência": "-",
    "Taxa de Performance": "-"
  },
  {
    "Fundo": "CAIXA ESG FIC FI BDR de Ações e BDR de ETF Ações",
    "Enquadramento 5.272/25": "Art. 8º - Inciso III",
    "CNPJ do Fundo": "43.760.251/0001-87",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "1.00%",
    "Índice de Referência": "-",
    "Taxa de Performance": "-"
  },
  {
    "Fundo": "CAIXA MASTER ESG Fundo de Ações em Geral BDR NÍVEL I",
    "Enquadramento 5.272/25": "Art. 8º - Inciso III",
    "CNPJ do Fundo": "42.195.992/0001-08",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "0.00%",
    "Índice de Referência": "-",
    "Taxa de Performance": "-"
  },
  {
    "Fundo": "BNB IMA-B FUNDO DE INVESTIMENTO RENDA FIXA",
    "Enquadramento 5.272/25": "Art. 7º, Inciso I ",
    "CNPJ do Fundo": "08.266.261/0001-60",
    "Administrador": "Banco do Nordeste do Brasil S/A",
    "Taxa de Adm.": "0.20%",
    "Índice de Referência": "IMA-B",
    "Taxa de Performance": "Não há"
  },
  {
    "Fundo": "BNB INSTITUCIONAL FUNDO DE INVESTIMENTO RENDA FIXA",
    "Enquadramento 5.272/25": "Art. 7º, Inciso V ",
    "CNPJ do Fundo": "21.307.581/0001-89",
    "Administrador": "Banco do Nordeste do Brasil S/A",
    "Taxa de Adm.": "0.35%",
    "Índice de Referência": "CDI",
    "Taxa de Performance": "Não há"
  },
  {
    "Fundo": "BNB FUNDO DE INVESTIMENTO FI Multimercado Aberto LONGO PRAZO",
    "Enquadramento 5.272/25": "Art. 10º, Inciso I",
    "CNPJ do Fundo": "06.124.248/0001-40",
    "Administrador": "Banco do Nordeste do Brasil S/A",
    "Taxa de Adm.": "0.20%",
    "Índice de Referência": "CDI",
    "Taxa de Performance": "Não há"
  },
  {
    "Fundo": "BNB PLUS FUNDO DE INVESTIMENTO EM COTAS DE FUNDO DE INVESTIMENTO\nRENDA FIXA LONGO PRAZO",
    "Enquadramento 5.272/25": "Art. 7º,  Inciso V",
    "CNPJ do Fundo": "06.124.241/0001-29",
    "Administrador": "Banco do Nordeste do Brasil S/A",
    "Taxa de Adm.": "0.50%",
    "Índice de Referência": "CDI",
    "Taxa de Performance": "Não há"
  },
  {
    "Fundo": "BNB SELEÇÃO FUNDO DE INVESTIMENTO AÇÕES",
    "Enquadramento 5.272/25": "Art. 8º, Inciso I ",
    "CNPJ do Fundo": "63.375.216/0001-51",
    "Administrador": "Banco do Nordeste do Brasil S/A",
    "Taxa de Adm.": "2.00%",
    "Índice de Referência": "IBOVESPA",
    "Taxa de Performance": "Não há"
  },
  {
    "Fundo": "BNB SOBERANO FUNDO DE INVESTIMENTO RENDA FIXA",
    "Enquadramento 5.272/25": "Art. 7º, Inciso I ",
    "CNPJ do Fundo": "30.568.193/0001-42",
    "Administrador": "Banco do Nordeste do Brasil S/A",
    "Taxa de Adm.": "0.20%",
    "Índice de Referência": "CDI",
    "Taxa de Performance": "Não há"
  },
  {
    "Fundo": "BNB IRF-M 1 TÍTULOS PÚBLICOS FI RENDA FIXA",
    "Enquadramento 5.272/25": "Art. 7º, Inciso I ",
    "CNPJ do Fundo": "35.816.816/0001-72",
    "Administrador": "Banco do Nordeste do Brasil S/A",
    "Taxa de Adm.": "0.20%",
    "Índice de Referência": "IRF-M 1",
    "Taxa de Performance": "Não há."
  },
  {
    "Fundo": "BNB CDB 100,50%",
    "Enquadramento 5.272/25": "Art. 7º, Inciso VI",
    "CNPJ do Fundo": "62.318.407/0001-19",
    "Administrador": "Banco do Nordeste do Brasil S/A",
    "Taxa de Adm.": "0.00%",
    "Índice de Referência": "CDI",
    "Taxa de Performance": "Não há."
  },
  {
    "Fundo": "CAIXA ELETROBRAS RESP LIMITADA FIF AÇÕES",
    "Enquadramento 5.272/25": "Art. 8º, Inciso I ",
    "CNPJ do Fundo": "45.443.475/0001-90",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "0.45%",
    "Índice de Referência": "IBOVESPA",
    "Taxa de Performance": "Não há."
  },
  {
    "Fundo": "BB PREVIDENCIÁRIO RENDA FIXA IMA-B 5 LONGO PRAZO FIC DE FI",
    "Enquadramento 5.272/25": "Art. 7º, Inciso I ",
    "CNPJ do Fundo": "03.543.447/0001-03",
    "Administrador": "BB GESTAO DE RECURSOS",
    "Taxa de Adm.": "0.20%",
    "Índice de Referência": "IMA-B 5",
    "Taxa de Performance": "Não há."
  },
  {
    "Fundo": "BB INSTITUCIONAL FUNDO DE INVESTIMENTO RENDA FIXA",
    "Enquadramento 5.272/25": "Art. 7º,  Inciso V",
    "CNPJ do Fundo": "02.296.928/0001-90",
    "Administrador": "BB GESTAO DE RECURSOS",
    "Taxa de Adm.": "0.20%",
    "Índice de Referência": "CDI",
    "Taxa de Performance": "Não há."
  },
  {
    "Fundo": "BB PREVIDENCIÁRIO RENDA FIXA IMA-B FI",
    "Enquadramento 5.272/25": "Art. 7º,  Inciso V",
    "CNPJ do Fundo": "07.861.554/0001-22",
    "Administrador": "BB GESTAO DE RECURSOS",
    "Taxa de Adm.": "0.60%",
    "Índice de Referência": "IMA-B",
    "Taxa de Performance": "Não há."
  },
  {
    "Fundo": "B PREVID RF IRF-M TIT PUBLICOS FIF RESP LIM",
    "Enquadramento 5.272/25": "Art. 7º, Inciso I ",
    "CNPJ do Fundo": "07.111.384/0001-69",
    "Administrador": "BB GESTAO DE RECURSOS",
    "Taxa de Adm.": "0.20%",
    "Índice de Referência": "IRF-M",
    "Taxa de Performance": "Não há."
  },
  {
    "Fundo": "BB PREVID RF IMA-B TITULOS PUBLICOS FIF RESP LIM",
    "Enquadramento 5.272/25": "Art. 7º, Inciso I ",
    "CNPJ do Fundo": "07.442.078/0001-05",
    "Administrador": "BB GESTAO DE RECURSOS",
    "Taxa de Adm.": "0.20%",
    "Índice de Referência": "IMA-B",
    "Taxa de Performance": "Não há."
  },
  {
    "Fundo": "BB Previd TP IPCA",
    "Enquadramento 5.272/25": "Art. 7º, Inciso I ",
    "CNPJ do Fundo": "15.486.093/0001-83",
    "Administrador": "BB GESTAO DE RECURSOS",
    "Taxa de Adm.": "0.15%",
    "Índice de Referência": "IPCA",
    "Taxa de Performance": "Não há."
  },
  {
    "Fundo": "BB Previd RF TP IPCA I FI",
    "Enquadramento 5.272/25": "Art. 7º, Inciso I ",
    "CNPJ do Fundo": "19.303.793/0001-46",
    "Administrador": "BB GESTAO DE RECURSOS",
    "Taxa de Adm.": "0.15%",
    "Índice de Referência": "IPCA",
    "Taxa de Performance": "Não há."
  },
  {
    "Fundo": "BB RENDA FIXA LP TESOURO SELIC",
    "Enquadramento 5.272/25": "Art. 7º, Inciso I ",
    "CNPJ do Fundo": "04.857.834/0001-79",
    "Administrador": "BB GESTAO DE RECURSOS",
    "Taxa de Adm.": "0.30%",
    "Índice de Referência": "CDI",
    "Taxa de Performance": "Não há."
  },
  {
    "Fundo": "BB Previd RF TP IPCA III FI",
    "Enquadramento 5.272/25": "Art. 7º, Inciso I ",
    "CNPJ do Fundo": "19.303.795/0001-35",
    "Administrador": "BB GESTAO DE RECURSOS",
    "Taxa de Adm.": "0.20%",
    "Índice de Referência": "IPCA",
    "Taxa de Performance": "Não há."
  },
  {
    "Fundo": "BB Previd RF TP IPCA V FI",
    "Enquadramento 5.272/25": "Art. 7º, Inciso I ",
    "CNPJ do Fundo": "19.515.016/0001-65",
    "Administrador": "BB GESTAO DE RECURSOS",
    "Taxa de Adm.": "0.20%",
    "Índice de Referência": "IPCA",
    "Taxa de Performance": "Não há."
  },
  {
    "Fundo": "BB Previd RF TP IPCA VI FI",
    "Enquadramento 5.272/25": "Art. 7º, Inciso I ",
    "CNPJ do Fundo": "19.523.306/0001-50",
    "Administrador": "BB GESTAO DE RECURSOS",
    "Taxa de Adm.": "0.20%",
    "Índice de Referência": "IPCA",
    "Taxa de Performance": "Não há."
  },
  {
    "Fundo": "BB PREVID RF IRF-M1 TITULOS PUBLICOS FIC FI",
    "Enquadramento 5.272/25": "Art. 7º, Inciso I ",
    "CNPJ do Fundo": "11.328.882/0001-35",
    "Administrador": "BB GESTAO DE RECURSOS",
    "Taxa de Adm.": "0.30%",
    "Índice de Referência": "IRF-M 1",
    "Taxa de Performance": "Não há."
  },
  {
    "Fundo": "BB PREVID RF IMAB 5 TITULOS PUBLICOS FIF",
    "Enquadramento 5.272/25": "Art. 7º, Inciso I ",
    "CNPJ do Fundo": "13.327.340/0001-73",
    "Administrador": "BB GESTAO DE RECURSOS",
    "Taxa de Adm.": "0.20%",
    "Índice de Referência": "IMA-B 5+",
    "Taxa de Performance": "Não há."
  },
  {
    "Fundo": "BB PREVIDENCIÁRIO RENDA FIXA IDKA2 TÍTULOS PÚBLICOS FI",
    "Enquadramento 5.272/25": "Art. 7º, Inciso I ",
    "CNPJ do Fundo": "13.322.205/0001-35",
    "Administrador": "BB GESTAO DE RECURSOS",
    "Taxa de Adm.": "0.20%",
    "Índice de Referência": "IDKA IPCA 2A",
    "Taxa de Performance": "Não há."
  },
  {
    "Fundo": "BB PREVIDENCIÁRIO FLUXO RENDA FIXA SIMPLES FIC FI",
    "Enquadramento 5.272/25": "Art. 7º,  Inciso V",
    "CNPJ do Fundo": "13.077.415/0001-05",
    "Administrador": "BB GESTAO DE RECURSOS",
    "Taxa de Adm.": "1.00%",
    "Índice de Referência": "CDI",
    "Taxa de Performance": "Não há."
  },
  {
    "Fundo": "BB PREVIDENCIÁRIO RENDA FIXA PERFIL FIC DE FI",
    "Enquadramento 5.272/25": "Art. 7º,  Inciso V",
    "CNPJ do Fundo": "13.077.418/0001-49",
    "Administrador": "BB GESTAO DE RECURSOS",
    "Taxa de Adm.": "0.30%",
    "Índice de Referência": "CDI",
    "Taxa de Performance": "Não há."
  },
  {
    "Fundo": "BB PREVIDENCIARIO RF IDKA 2 TITULOS PUBLICOS FIF",
    "Enquadramento 5.272/25": "Art. 7º, Inciso I ",
    "CNPJ do Fundo": "14.964.240/0001-10",
    "Administrador": "BB GESTAO DE RECURSOS",
    "Taxa de Adm.": "0.20%",
    "Índice de Referência": "IMA GERAL",
    "Taxa de Performance": "Não há."
  },
  {
    "Fundo": "BB Previd RF Tit Pub VII FI",
    "Enquadramento 5.272/25": "Art. 7º, Inciso I ",
    "CNPJ do Fundo": "19.523.305/0001-06",
    "Administrador": "BB GESTAO DE RECURSOS",
    "Taxa de Adm.": "0.20%",
    "Índice de Referência": "IMA-B",
    "Taxa de Performance": "Não há."
  },
  {
    "Fundo": "BB Previd RF Tit Publ X FI",
    "Enquadramento 5.272/25": "Art. 7º, Inciso I ",
    "CNPJ do Fundo": "20.734.931/0001-20",
    "Administrador": "BB GESTAO DE RECURSOS",
    "Taxa de Adm.": "0.20%",
    "Índice de Referência": "IPCA",
    "Taxa de Performance": "Não há."
  },
  {
    "Fundo": "BB Previd RF Tit Pub XI FI",
    "Enquadramento 5.272/25": "Art. 7º, Inciso I ",
    "CNPJ do Fundo": "24.117.278/0001-01",
    "Administrador": "BB GESTAO DE RECURSOS",
    "Taxa de Adm.": "0.20%",
    "Índice de Referência": "IDkA IPCA 5 ANOS",
    "Taxa de Performance": "Não há."
  },
  {
    "Fundo": "BB PREVIDENCIÁRIO RF ALOCAÇÃO ATIVA FIC DE FI",
    "Enquadramento 5.272/25": "Art. 7º, Inciso I ",
    "CNPJ do Fundo": "25.078.994/0001-90",
    "Administrador": "BB GESTAO DE RECURSOS",
    "Taxa de Adm.": "0.50%",
    "Índice de Referência": "IMA-GERAL ex-C",
    "Taxa de Performance": "Não há."
  },
  {
    "Fundo": "BB PREVIDENCIARIO RF IRF-M 1 FIF",
    "Enquadramento 5.272/25": "Art. 7º, Inciso I ",
    "CNPJ do Fundo": "32.161.826/0001-29",
    "Administrador": "BB GESTAO DE RECURSOS",
    "Taxa de Adm.": "0.30%",
    "Índice de Referência": "IRF-M 1+",
    "Taxa de Performance": "Não há."
  },
  {
    "Fundo": "BB PREVIDENCIÁRIO RF ALOCAÇÃO ATIVA RETORNO TOTAL",
    "Enquadramento 5.272/25": "Art. 7º,  Inciso V",
    "CNPJ do Fundo": "35.292.588/0001-89",
    "Administrador": "BB GESTAO DE RECURSOS",
    "Taxa de Adm.": "0.50%",
    "Índice de Referência": "IPCA",
    "Taxa de Performance": "Não há."
  },
  {
    "Fundo": "BB RENDA FIXA CP AUTOMATICO SETOR PUBLICO FIC FIF",
    "Enquadramento 5.272/25": "Art. 7º, Inciso I ",
    "CNPJ do Fundo": "04.288.966/0001-27",
    "Administrador": "BB GESTAO DE RECURSOS",
    "Taxa de Adm.": "1.75%",
    "Índice de Referência": "CDI",
    "Taxa de Performance": "Não há."
  },
  {
    "Fundo": "BB PREVID. RF TÍTULOS PÚBLICOS VÉRTICE 2027 FI",
    "Enquadramento 5.272/25": "Art. 7º, Inciso I ",
    "CNPJ do Fundo": "46.134.096/0001-81",
    "Administrador": "BB GESTAO DE RECURSOS",
    "Taxa de Adm.": "0.20%",
    "Índice de Referência": "IPCA",
    "Taxa de Performance": "Não há."
  },
  {
    "Fundo": "BB PREV RENDA FIXA TP VERTICE ESPECIAL 2028",
    "Enquadramento 5.272/25": "Art. 7º, Inciso I ",
    "CNPJ do Fundo": "50.099.960/0001-29",
    "Administrador": "BB GESTAO DE RECURSOS",
    "Taxa de Adm.": "0.06%",
    "Índice de Referência": "IPCA",
    "Taxa de Performance": "Não há."
  },
  {
    "Fundo": "BB PREVIDENCIARIO VERTICE RENDA FIXA TP 2026",
    "Enquadramento 5.272/25": "Art. 7º, Inciso I ",
    "CNPJ do Fundo": "54.602.092/0001-09",
    "Administrador": "BB GESTAO DE RECURSOS",
    "Taxa de Adm.": "0.06%",
    "Índice de Referência": "IPCA",
    "Taxa de Performance": "Não há."
  },
  {
    "Fundo": "BB PREVID. RF TÍTULOS PÚBLICOS VÉRTICE 2027 II FI",
    "Enquadramento 5.272/25": "Art. 7º, Inciso I ",
    "CNPJ do Fundo": "55.746.782/0001-02",
    "Administrador": "BB GESTAO DE RECURSOS",
    "Taxa de Adm.": "0.06%",
    "Índice de Referência": "IPCA",
    "Taxa de Performance": "Não há."
  },
  {
    "Fundo": "Bradesco Institucional  FIC FI RF IMA-B Títulos Públicos",
    "Enquadramento 5.272/25": "Art. 7º, Inciso I ",
    "CNPJ do Fundo": "10.986.880/0001-70",
    "Administrador": "Banco Bradesco S/A",
    "Taxa de Adm.": "0.20%",
    "Índice de Referência": "IMA-B",
    "Taxa de Performance": "Não há"
  },
  {
    "Fundo": "Bradesco FI RF IRF-M 1 Títulos Públicos",
    "Enquadramento 5.272/25": "Art. 7º, Inciso I ",
    "CNPJ do Fundo": "11.484.558/0001-06",
    "Administrador": "Banco Bradesco S/A",
    "Taxa de Adm.": "0.20%",
    "Índice de Referência": "IRF-M 1",
    "Taxa de Performance": "Não há"
  },
  {
    "Fundo": "Bradesco FI RF IDKA PRÉ 2 ",
    "Enquadramento 5.272/25": "Art. 7º,  Inciso V",
    "CNPJ do Fundo": "24.022.566/0001-82",
    "Administrador": "Banco Bradesco S/A",
    "Taxa de Adm.": "0.20%",
    "Índice de Referência": "IDKA PRÉ 2 ",
    "Taxa de Performance": "Não há"
  },
  {
    "Fundo": "Bradesco Institucional  FIC FI RF IMA-Geral",
    "Enquadramento 5.272/25": "Art. 7º,  Inciso V",
    "CNPJ do Fundo": "08.246.318/0001-69",
    "Administrador": "Banco Bradesco S/A",
    "Taxa de Adm.": "0.25%",
    "Índice de Referência": "IMA GERAL",
    "Taxa de Performance": "Não há"
  },
  {
    "Fundo": "Bradesco Institucional  FIC FI RF IMA-B",
    "Enquadramento 5.272/25": "Art. 7º,  Inciso V",
    "CNPJ do Fundo": "08.702.798/0001-25",
    "Administrador": "Banco Bradesco S/A",
    "Taxa de Adm.": "0.20%",
    "Índice de Referência": "IMA - B",
    "Taxa de Performance": "Não há"
  },
  {
    "Fundo": "Bradesco Institucional  FIC FI RF IMA-B 5 +",
    "Enquadramento 5.272/25": "Art. 7º,  Inciso V",
    "CNPJ do Fundo": "13.400.077/0001-09",
    "Administrador": "Banco Bradesco S/A",
    "Taxa de Adm.": "0.20%",
    "Índice de Referência": "IMA-B 5 +",
    "Taxa de Performance": "Não há"
  },
  {
    "Fundo": "Bradesco Institucional  FIC FI RF IMA-B 5 ",
    "Enquadramento 5.272/25": "Art. 7º,  Inciso V",
    "CNPJ do Fundo": "20.216.216/0001-04",
    "Administrador": "Banco Bradesco S/A",
    "Taxa de Adm.": "0.20%",
    "Índice de Referência": "IMA-B 5",
    "Taxa de Performance": "Não há"
  },
  {
    "Fundo": "Bradesco FIC FI RF Referenciado DI Poder Público",
    "Enquadramento 5.272/25": "Art. 7º,  Inciso V",
    "CNPJ do Fundo": "07.187.570/0001-81",
    "Administrador": "Banco Bradesco S/A",
    "Taxa de Adm.": "0.90%",
    "Índice de Referência": "CDI",
    "Taxa de Performance": "Não há"
  },
  {
    "Fundo": "Bradesco FI RF Referenciado DI Premium",
    "Enquadramento 5.272/25": "Art. 7º,  Inciso V",
    "CNPJ do Fundo": "03.399.411/0001-90",
    "Administrador": "Banco Bradesco S/A",
    "Taxa de Adm.": "0.20%",
    "Índice de Referência": "CDI",
    "Taxa de Performance": "Não há"
  },
  {
    "Fundo": "Bradesco FI RF Referenciado DI Federal Extra",
    "Enquadramento 5.272/25": "Art. 7º, Inciso I ",
    "CNPJ do Fundo": "03.256.793/0001-00",
    "Administrador": "Banco Bradesco S/A",
    "Taxa de Adm.": "0.15%",
    "Índice de Referência": "CDI",
    "Taxa de Performance": "Não há"
  },
  {
    "Fundo": "Bradesco FIC Renda Fixa Alocação Dinâmica ",
    "Enquadramento 5.272/25": "Art. 7º,  Inciso V",
    "CNPJ do Fundo": "28.515.874/0001-09",
    "Administrador": "Banco Bradesco S/A",
    "Taxa de Adm.": "0.40%",
    "Índice de Referência": "IPCA",
    "Taxa de Performance": "Não há"
  },
  {
    "Fundo": "Bradesco H FIC FIA Ibovespa Regimes de Previdência",
    "Enquadramento 5.272/25": "Art. 8º, Inciso I ",
    "CNPJ do Fundo": "11.232.995/0001-32",
    "Administrador": "Banco Bradesco S/A",
    "Taxa de Adm.": "1.00%",
    "Índice de Referência": "IBOVESPA",
    "Taxa de Performance": "Não há"
  },
  {
    "Fundo": "Bradesco H FIC FIM Macro Institucional",
    "Enquadramento 5.272/25": "Art. 10º, Inciso I",
    "CNPJ do Fundo": "21.287.421/0001-15",
    "Administrador": "Banco Bradesco S/A",
    "Taxa de Adm.": "0.50%",
    "Índice de Referência": "CDI",
    "Taxa de Performance": "20%"
  },
  {
    "Fundo": "Bradesco FIA Ibovespa Plus",
    "Enquadramento 5.272/25": "Art. 8º, Inciso I ",
    "CNPJ do Fundo": "03.394.711/0001-86",
    "Administrador": "Banco Bradesco S/A",
    "Taxa de Adm.": "0.50%",
    "Índice de Referência": "IBOVESPA",
    "Taxa de Performance": "Não há"
  },
  {
    "Fundo": "Bradesco H FI RF Nilo",
    "Enquadramento 5.272/25": "Art. 7º, Inciso I ",
    "CNPJ do Fundo": "15.259.071/0001-80",
    "Administrador": "Banco Bradesco S/A",
    "Taxa de Adm.": "0.30%",
    "Índice de Referência": "IMA-B",
    "Taxa de Performance": "20%"
  },
  {
    "Fundo": "Bradesco H FIA Dividendos",
    "Enquadramento 5.272/25": "Art. 8º, Inciso I ",
    "CNPJ do Fundo": "02.138.442/0001-24",
    "Administrador": "Banco Bradesco S/A",
    "Taxa de Adm.": "1.00%",
    "Índice de Referência": "IDIV11",
    "Taxa de Performance": "Não há"
  },
  {
    "Fundo": "Bradesco FIM Plus I (*)",
    "Enquadramento 5.272/25": "Art. 10º, Inciso I",
    "CNPJ do Fundo": "02.998.164/0001-85",
    "Administrador": "Banco Bradesco S/A",
    "Taxa de Adm.": "0.50%",
    "Índice de Referência": "CDI",
    "Taxa de Performance": "20%"
  },
  {
    "Fundo": "Bradesco FIM S&P® 500 Mais",
    "Enquadramento 5.272/25": "Art. 10º, Inciso I",
    "CNPJ do Fundo": "18.079.540/0001-78",
    "Administrador": "Banco Bradesco S/A",
    "Taxa de Adm.": "1.50%",
    "Índice de Referência": "S&P 500",
    "Taxa de Performance": "20%"
  },
  {
    "Fundo": "Bradesco FIC FI Curto Prazo Poder Público",
    "Enquadramento 5.272/25": "Art. 7º,  Inciso V",
    "CNPJ do Fundo": "13.397.466/0001-14",
    "Administrador": "Banco Bradesco S/A",
    "Taxa de Adm.": "1.50%",
    "Índice de Referência": "CDI",
    "Taxa de Performance": "Não há"
  },
  {
    "Fundo": "Bradesco H FIA Ibovespa Valuation",
    "Enquadramento 5.272/25": "Art. 8º, Inciso I ",
    "CNPJ do Fundo": "11.675.309/0001-06",
    "Administrador": "Banco Bradesco S/A",
    "Taxa de Adm.": "2.00%",
    "Índice de Referência": "CDI",
    "Taxa de Performance": "20%"
  },
  {
    "Fundo": "Bradesco H FIA Small Caps",
    "Enquadramento 5.272/25": "Art. 8º, Inciso I ",
    "CNPJ do Fundo": "07.986.196/0001-84",
    "Administrador": "Banco Bradesco S/A",
    "Taxa de Adm.": "1.00%",
    "Índice de Referência": "SMLL",
    "Taxa de Performance": "Não há"
  },
  {
    "Fundo": "Bradesco FI RF Maxi Poder Público",
    "Enquadramento 5.272/25": "Art. 7º, Inciso I ",
    "CNPJ do Fundo": "08.246.263/0001-97",
    "Administrador": "Banco Bradesco S/A",
    "Taxa de Adm.": "0.20%",
    "Índice de Referência": "CDI",
    "Taxa de Performance": "Não há"
  },
  {
    "Fundo": "BRADESCO FI FINANCEIRO RENDA FIXA ESTRATÉGIA XXVI",
    "Enquadramento 5.272/25": "Art. 7º, Inciso I ",
    "CNPJ do Fundo": "55.969.096/0001-92",
    "Administrador": "Banco Bradesco S/A",
    "Taxa de Adm.": "0.05%",
    "Índice de Referência": "IPCA",
    "Taxa de Performance": "Não há"
  },
  {
    "Fundo": "BB RENDA FIXA LP TESOURO SELIC",
    "Enquadramento 5.272/25": "Art. 7º, Inciso I ",
    "CNPJ do Fundo": "04.857.834/0001-79",
    "Administrador": "BB GESTAO DE RECURSOS",
    "Taxa de Adm.": "0.20%",
    "Índice de Referência": "CDI",
    "Taxa de Performance": "Não há."
  },
  {
    "Fundo": "Bradesco FIC RF Referenciado DI Federal",
    "Enquadramento 5.272/25": "Art. 7º,  Inciso V",
    "CNPJ do Fundo": "00.824.198/0001-28",
    "Administrador": "Banco Bradesco S/A",
    "Taxa de Adm.": "1.00%",
    "Índice de Referência": "CDI",
    "Taxa de Performance": "Não há."
  },
  {
    "Fundo": "Bradesco Alocação Sistemática FIC FI RF Brasil",
    "Enquadramento 5.272/25": "Art. 7º,  Inciso V",
    "CNPJ do Fundo": "44.981.897/0001-57",
    "Administrador": "Banco Bradesco S/A",
    "Taxa de Adm.": "0.45%",
    "Índice de Referência": "IBX",
    "Taxa de Performance": "20%"
  },
  {
    "Fundo": "BRADESCO FIC RF IDKA PRÉ 5",
    "Enquadramento 5.272/25": "Art. 7º,  Inciso V",
    "CNPJ do Fundo": "49.176.765/0001-76",
    "Administrador": "Banco Bradesco S/A",
    "Taxa de Adm.": "0.20%",
    "Índice de Referência": "CDI",
    "Taxa de Performance": "Não há."
  },
  {
    "Fundo": "Bradesco FIC Renda Fixa IDKA IPCA 2",
    "Enquadramento 5.272/25": "Art. 7º,  Inciso V",
    "CNPJ do Fundo": "44.273.776/0001-50",
    "Administrador": "Banco Bradesco S/A",
    "Taxa de Adm.": "0.20%",
    "Índice de Referência": "CDI",
    "Taxa de Performance": "Não há."
  },
  {
    "Fundo": "BRADESCO FIC FI RF IDKA IPCA 5",
    "Enquadramento 5.272/25": "Art. 7º,  Inciso V",
    "CNPJ do Fundo": "49.173.111/0001-99",
    "Administrador": "Banco Bradesco S/A",
    "Taxa de Adm.": "0.20%",
    "Índice de Referência": "CDI",
    "Taxa de Performance": "Não há."
  },
  {
    "Fundo": "Bradesco FIA Dividendos",
    "Enquadramento 5.272/25": "Art. 8º, Inciso I ",
    "CNPJ do Fundo": "06.916.384/0001-73",
    "Administrador": "Banco Bradesco S/A",
    "Taxa de Adm.": "1.50%",
    "Índice de Referência": "IBOVESPA",
    "Taxa de Performance": "Não há."
  },
  {
    "Fundo": "CAIXA TOPÁZIO FIF RENDA FIXA REFERENCIADO DI LP*",
    "Enquadramento 5.272/25": "Art. 7º, Inciso I ",
    "CNPJ do Fundo": "11.061.230/0001-87",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "0.10%",
    "Índice de Referência": "CDI",
    "Taxa de Performance": "Não há."
  },
  {
    "Fundo": "CAIXA BRASIL IDKA PRÉ 2A RESP LIMITADA FIF CIC RENDA FIXA LP",
    "Enquadramento 5.272/25": "Art. 7º, Inciso I ",
    "CNPJ do Fundo": "45.163.710/0001-70",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "0.20%",
    "Índice de Referência": "IDKA PRE 2A",
    "Taxa de Performance": "Não há."
  },
  {
    "Fundo": "CAIXA BRASIL IMA-B TÍTULOS PÚBLICOS RESP LIMITADA FIF RENDA FIXA LP",
    "Enquadramento 5.272/25": "Art. 7º, Inciso I ",
    "CNPJ do Fundo": "10.740.658/0001-93",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "0.20%",
    "Índice de Referência": "IMA-B",
    "Taxa de Performance": "Não há."
  },
  {
    "Fundo": "CAIXA BRASIL 2026 X TÍTULOS PÚBLICOS RESP LIMITADA FIF RENDA FIXA",
    "Enquadramento 5.272/25": "Art. 7º, Inciso I ",
    "CNPJ do Fundo": "54.518.391/0001-60",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "0.10%",
    "Índice de Referência": "IPCA + TAXA 5% AA CO",
    "Taxa de Performance": "Não há."
  },
  {
    "Fundo": "CAIXA BRASIL 2027 TÍTULOS PÚBLICOS RESP LIMITADA FIF RENDA FIXA",
    "Enquadramento 5.272/25": "Art. 7º, Inciso I ",
    "CNPJ do Fundo": "45.443.514/0001-50",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "0.20%",
    "Índice de Referência": "IPCA + TAXA 5% AA CO",
    "Taxa de Performance": "Não há."
  },
  {
    "Fundo": "CAIXA BRASIL 2027 X TÍTULOS PÚBLICOS RESP LIMITADA FIF RENDA FIXA",
    "Enquadramento 5.272/25": "Art. 7º, Inciso I ",
    "CNPJ do Fundo": "50.642.114/0001-03",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "0.15%",
    "Índice de Referência": "IPCA + TAXA 5% AA CO",
    "Taxa de Performance": "Não há."
  },
  {
    "Fundo": "CAIXA BRASIL 2028 X TÍTULOS PÚBLICOS RESP LIMITADA FIF RENDA FIXA",
    "Enquadramento 5.272/25": "Art. 7º, Inciso I ",
    "CNPJ do Fundo": "50.470.807/0001-66",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "0.15%",
    "Índice de Referência": "IPCA + TAXA 5% AA CO",
    "Taxa de Performance": "Não há."
  },
  {
    "Fundo": "CAIXA BRASIL 2030 I TÍTULOS PÚBLICOS RESP LIMITADA FIF RENDA FIXA",
    "Enquadramento 5.272/25": "Art. 7º, Inciso I ",
    "CNPJ do Fundo": "18.598.042/0001-31",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "0.20%",
    "Índice de Referência": "IPCA",
    "Taxa de Performance": "Não há."
  },
  {
    "Fundo": "CAIXA BRASIL 2030 II TÍTULOS PÚBLICOS RESP LIMITADA FIF RENDA FIXA",
    "Enquadramento 5.272/25": "Art. 7º, Inciso I ",
    "CNPJ do Fundo": "19.769.046/0001-06",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "0.20%",
    "Índice de Referência": "IMA-B",
    "Taxa de Performance": "Não há."
  },
  {
    "Fundo": "CAIXA BRASIL 2030 III TÍTULOS PÚBLICOS RESP LIMITADA FIF RENDA FIXA",
    "Enquadramento 5.272/25": "Art. 7º, Inciso I ",
    "CNPJ do Fundo": "20.139.534/0001-00",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "0.20%",
    "Índice de Referência": "IMA-B",
    "Taxa de Performance": "Não há."
  },
  {
    "Fundo": "CAIXA BRASIL 2030 X TÍTULOS PÚBLICOS RESP LIMITADA FIF RENDA FIXA",
    "Enquadramento 5.272/25": "Art. 7º, Inciso I ",
    "CNPJ do Fundo": "50.658.938/0001-71",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "0.15%",
    "Índice de Referência": "IPCA + TAXA 5% AA CO",
    "Taxa de Performance": "Não há."
  },
  {
    "Fundo": "CAIXA BRASIL 2032 X TÍTULOS PÚBLICOS RESP LIMITADA FIF RENDA FIXA",
    "Enquadramento 5.272/25": "Art. 7º, Inciso I ",
    "CNPJ do Fundo": "50.568.762/0001-67",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "0.15%",
    "Índice de Referência": "IPCA + TAXA 5% AA CO",
    "Taxa de Performance": "Não há."
  },
  {
    "Fundo": "CAIXA BRASIL 2033 X TÍTULOS PÚBLICOS RESP LIMITADA FIF RENDA FIXA",
    "Enquadramento 5.272/25": "Art. 7º, Inciso I ",
    "CNPJ do Fundo": "50.569.054/0001-40",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "0.15%",
    "Índice de Referência": "IPCA + TAXA 5% AA CO",
    "Taxa de Performance": "Não há."
  },
  {
    "Fundo": "CAIXA BRASIL 2035 X TÍTULOS PÚBLICOS RESP LIMITADA FIF RENDA FIXA",
    "Enquadramento 5.272/25": "Art. 7º, Inciso I ",
    "CNPJ do Fundo": "54.390.568/0001-95",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "0.10%",
    "Índice de Referência": "IPCA + TAXA 5% AA CO",
    "Taxa de Performance": "Não há."
  },
  {
    "Fundo": "CAIXA BRASIL 2040 X TÍTULOS PÚBLICOS RESP LIMITADA FIF RENDA FIXA",
    "Enquadramento 5.272/25": "Art. 7º, Inciso I ",
    "CNPJ do Fundo": "54.390.771/0001-61",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "0.10%",
    "Índice de Referência": "IPCA + TAXA 5% AA CO",
    "Taxa de Performance": "Não há."
  },
  {
    "Fundo": "CAIXA BRASIL ESPECIAL 2026 TÍTULOS PÚBLICOS RESP LIMITADA FIF RENDA FIXA",
    "Enquadramento 5.272/25": "Art. 7º, Inciso I ",
    "CNPJ do Fundo": "56.134.800/0001-50",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "0.06%",
    "Índice de Referência": "IPCA + TAXA 5% AA CO",
    "Taxa de Performance": "Não há."
  },
  {
    "Fundo": "CAIXA BRASIL ESPECIAL 2032 TÍTULOS PÚBLICOS RESP LIMITADA FIF RENDA FIXA",
    "Enquadramento 5.272/25": "Art. 7º, Inciso I ",
    "CNPJ do Fundo": "56.209.706/0001-12",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "0.06%",
    "Índice de Referência": "IPCA + TAXA 5% AA CO",
    "Taxa de Performance": "Não há."
  },
  {
    "Fundo": "CAIXA BRASIL ESPECIAL 2033 TÍTULOS PÚBLICOS RESP LIMITADA FIF RENDA FIXA",
    "Enquadramento 5.272/25": "Art. 7º, Inciso I ",
    "CNPJ do Fundo": "56.209.979/0001-67",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "0.06%",
    "Índice de Referência": "IPCA + TAXA 5% AA CO",
    "Taxa de Performance": "Não há."
  },
  {
    "Fundo": "CAIXA TOP PRIVATE RESP LIMITADA FIC FIF RENDA FIXA REFERENCIADO DI LP",
    "Enquadramento 5.272/25": "Art. 7º, Inciso V ",
    "CNPJ do Fundo": "19.769.018/0001-80",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "0.15%",
    "Índice de Referência": "CDI",
    "Taxa de Performance": "Não há."
  },
  {
    "Fundo": "CAIXA FI MEGA RF REFERENCIADO DI LP",
    "Enquadramento 5.272/25": "Art. 7º, Inciso V ",
    "CNPJ do Fundo": "10.322.633/0001-70",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "0.25%",
    "Índice de Referência": "CDI",
    "Taxa de Performance": "Não há."
  },
  {
    "Fundo": "CAIXA EXPERT ABSOLUTE CRETA RESP LIMITADA FIF CIC RF CRÉDITO PRIVADO LP (1)",
    "Enquadramento 5.272/25": "Art. 7º, Inciso VII ",
    "CNPJ do Fundo": "59.861.817/0001-05",
    "Administrador": "Caixa Econômica Federal"
  },
  {
    "Fundo": "CAIXA EXPERT SULAMÉRICA CRÉDITO ATIVO RESP LIMITADA FIF CIC RF CRÉDITO PRIVADO LP",
    "Enquadramento 5.272/25": "Art. 7º, Inciso VII ",
    "CNPJ do Fundo": "58.113.332/0001-62",
    "Administrador": "Caixa Econômica Federal"
  },
  {
    "Fundo": "CAIXA DIVIDENDOS QUANTITATIVO RESP LIMITADA FIF CIC AÇÕES",
    "Enquadramento 5.272/25": "Art. 8º, Inciso I ",
    "CNPJ do Fundo": "42.120.405/0001-03",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "2.00%",
    "Índice de Referência": "IDIV",
    "Taxa de Performance": "20%"
  },
  {
    "Fundo": "CAIXA INDEXA IAGRO RESP LIMITADA FIF AÇÕES",
    "Enquadramento 5.272/25": "Art. 8º, Inciso I ",
    "CNPJ do Fundo": "45.443.601/0001-07",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "0.80%",
    "Índice de Referência": "IAGRO-FFS B3",
    "Taxa de Performance": "Não há."
  },
  {
    "Fundo": "CAIXA PETROBRAS PRÉ SAL RESP LIMITADA FIF AÇÕES 03.914.671/0001-56",
    "Enquadramento 5.272/25": "Art. 8º, Inciso I ",
    "CNPJ do Fundo": "11.060.594/0001-42",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "0.50%",
    "Índice de Referência": "PETR4",
    "Taxa de Performance": "Não há."
  },
  {
    "Fundo": "CAIXA EXPERT PIMCO INCOME INV EXTERIOR RESP LIMITADA FIF CIC MULTIMERCADO LP",
    "Enquadramento 5.272/25": "Art. 9º, Inciso III ",
    "CNPJ do Fundo": "51.659.921/0001-00",
    "Administrador": "Caixa Econômica Federal"
  },
  {
    "Fundo": "CAIXA CAPITAL PROTEGIDO BOLSA DE VALORES IV RESP LIMITADA FIF CIC MULTIMERCADO",
    "Enquadramento 5.272/25": "Art. 10º, Inciso I",
    "CNPJ do Fundo": "44.683.343/0001-73",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "0.90%",
    "Índice de Referência": "IBOVESPA",
    "Taxa de Performance": "Não há."
  },
  {
    "Fundo": "CAIXA CAPITAL PROTEGIDO IBOVESPA CÍCLICO I RESP LIMITADA FIF CIC MULTIMERCADO",
    "Enquadramento 5.272/25": "Art. 10º, Inciso I",
    "CNPJ do Fundo": "14.239.659/0001-00",
    "Administrador": "Caixa Econômica Federal",
    "Taxa de Adm.": "1.60%",
    "Índice de Referência": "IBOVESPA",
    "Taxa de Performance": "Não há."
  }
].freeze
# =============================================================
# HELPER UTILITIES
# =============================================================

# == sanitize_abbreviation
#
# @author Moisés Reis
#
# Remove caracteres especiais de uma string e limita o resultado aos
# primeiros 10 caracteres para satisfazer as restrições do banco de dados.
#
# Parameters:: - *text* - A string original do índice (ex: "IDKA IPCA 5 ANOS").
#
# Returns:: - A string sanitizada e truncada (ex: "IDKAIPCA5A").
def sanitize_abbreviation(text)
  return "" if text.blank?

  # Explanation:: Esta instrução remove caracteres não alfanuméricos e aplica
  #               um limite rigoroso de 10 caracteres no final da string.
  text.to_s.gsub(/[^a-zA-Z0-9]/, "").upcase[0...10]
end

# == parse_decimal_value
#
# @author Moisés Reis
#
# Converte valores em formato de string (porcentagem) para BigDecimal,
# tratando casos de valores ausentes ou hifens.
#
# Parameters:: - *value* - O valor textual vindo da fonte de dados.
#
# Returns:: - Um objeto BigDecimal representando o valor numérico.
def parse_decimal_value(value)
  return BigDecimal("0") if value.blank? || value == "-"

  clean_value = value.to_s.gsub("%", "").gsub(",", ".").strip

  BigDecimal(clean_value)
rescue ArgumentError
  BigDecimal("0")
end

# == normalize_article_number
#
# @author Moisés Reis
#
# Padroniza a string de referência do artigo para facilitar a busca
# no banco de dados através de comparações de texto.
#
# Parameters:: - *text* - O enquadramento legal original.
#
# Returns:: - String normalizada para consulta.
def normalize_article_number(text)
  return "" if text.blank?

  text.gsub(/[^\w\sºº,]/i, "").strip
end

# =============================================================
# MAIN SEEDING PROCESS
# =============================================================

# Explanation:: Inicia o processo de inserção de dados garantindo que falhas
#               em registros individuais não deixem o banco em estado parcial.
ActiveRecord::Base.transaction do
  FUNDS_DATA.each do |data|
    fund = InvestmentFund.find_or_initialize_by(cnpj: data[:"CNPJ do Fundo"])

    if data[:"Índice de Referência"].present? && data[:"Índice de Referência"] != "-"
      raw_index = data[:"Índice de Referência"]
      clean_abbr = sanitize_abbreviation(raw_index)

      # Explanation:: Verifica se o índice já existe por abreviação ou nome
      #               antes de tentar criar um novo registro para evitar erros.
      index = EconomicIndex.find_by(abbreviation: clean_abbr)
      index ||= EconomicIndex.find_by("LOWER(name) = ?", raw_index.downcase)

      index ||= EconomicIndex.create!(
        abbreviation: clean_abbr,
        name: raw_index
      )

      fund.benchmark_index = index.abbreviation
    end

    fund.fund_name = data[:Fundo]

    fund.administrator_name = data[:Administrador]

    fund.administration_fee = parse_decimal_value(data[:"Taxa de Adm."])

    fund.performance_fee = parse_decimal_value(data[:"Taxa de Performance"])

    if fund.save!
      article_ref = normalize_article_number(data[:"Enquadramento 5.272/25"])

      article = NormativeArticle.find_by("article_number ILIKE ?", "#{article_ref}%")

      if article
        # Explanation:: Associa o fundo ao artigo normativo apenas se o
        #               vínculo ainda não estiver registrado no sistema.
        InvestmentFundArticle.find_or_create_by!(
          investment_fund: fund,
          normative_article: article
        )
      end
    end
  end
end
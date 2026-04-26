# Defines FactoryBot factories for the FundValuation model.
#
# This factory represents daily valuation snapshots for an investment fund,
# including quota value and data source attribution.
#
# TABLE OF CONTENTS:
#   1.  Base Factory Definition
#
# @author Moisés Reis

FactoryBot.define do
  # =============================================================
  #                  1. BASE FACTORY DEFINITION
  # =============================================================

  # Factory for creating FundValuation records with valid default attributes.
  #
  # Associations:
  # - investment_fund: The fund being valued. Uses :create strategy to ensure
  #   persistence for dependent attributes (e.g., CNPJ).
  #
  # Attributes:
  # - date:        Valuation reference date.
  # - fund_cnpj:   Identifier copied from the associated InvestmentFund.
  # - quota_value: Per-quota value at the given date.
  # - source:      Data provider identifier (e.g., "CVM").
  #
  # @return [FundValuation] A valid FundValuation instance.
  factory :fund_valuation do
    association :investment_fund, strategy: :create

    date        { Date.current }
    fund_cnpj   { investment_fund.cnpj }
    quota_value { BigDecimal("100.0") }
    source      { "CVM" }
  end
end

# Defines FactoryBot factories for the FundInvestment model.
#
# This factory creates portfolio-to-fund allocation records, representing
# how much of a given portfolio is invested in a specific investment fund.
#
# TABLE OF CONTENTS:
#   1.  Base Factory Definition
#
# @author Moisés Reis

FactoryBot.define do
  # =============================================================
  #                  1. BASE FACTORY DEFINITION
  # =============================================================

  # Factory for creating FundInvestment records with valid default attributes.
  #
  # Associations:
  # - portfolio:        The owning Portfolio instance.
  # - investment_fund:  The associated InvestmentFund.
  #
  # Attributes:
  # - total_invested_value:  Total capital invested in the fund.
  # - percentage_allocation: Percentage of the portfolio allocated to this fund.
  # - total_quotas_held:     Number of fund quotas held.
  #
  # @return [FundInvestment] A valid FundInvestment instance.
  factory :fund_investment do
    association :portfolio
    association :investment_fund

    total_invested_value  { BigDecimal("100000.00") }
    percentage_allocation { BigDecimal("100.0") }
    total_quotas_held     { BigDecimal("1000.0") }
  end
end

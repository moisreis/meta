# Defines FactoryBot factories for the InvestmentFund model.
#
# This factory generates valid investment fund records with realistic attributes,
# including unique identifiers (CNPJ) and fee structures represented as BigDecimal.
#
# TABLE OF CONTENTS:
#   1.  Base Factory Definition
#
# @author Moisés Reis

FactoryBot.define do
  # =============================================================
  #                  1. BASE FACTORY DEFINITION
  # =============================================================

  # Factory for creating InvestmentFund records with valid default attributes.
  #
  # Attributes:
  # - fund_name:          Random company name suffixed with "FIC FIM".
  # - cnpj:               Unique 14-digit numeric string representing the fund identifier.
  # - administrator_name: Random company name acting as fund administrator.
  # - administration_fee: Management fee percentage as BigDecimal.
  # - performance_fee:    Performance fee percentage as BigDecimal.
  #
  # @return [InvestmentFund] A valid InvestmentFund instance.
  factory :investment_fund do
    fund_name          { Faker::Company.name + " FIC FIM" }
    cnpj               { format('%014d', Faker::Number.unique.number(digits: 14)) }
    administrator_name { Faker::Company.name }
    administration_fee { BigDecimal("0.5") }
    performance_fee    { BigDecimal("20.0") }
  end
end

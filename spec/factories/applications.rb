# Defines FactoryBot factories for the Application model.
#
# This factory represents capital allocation events into an investment fund,
# capturing key financial and lifecycle dates associated with the application.
#
# TABLE OF CONTENTS:
#   1.  Base Factory Definition
#
# @author Moisés Reis

FactoryBot.define do
  # =============================================================
  #                  1. BASE FACTORY DEFINITION
  # =============================================================

  # Factory for creating Application records with valid default attributes.
  #
  # Associations:
  # - fund_investment: The related FundInvestment representing the target allocation.
  #
  # Attributes:
  # - request_date:               Date the application request was made.
  # - cotization_date:            Date used to determine the quota value.
  # - liquidation_date:           Date the application is settled.
  # - financial_value:            Monetary amount invested.
  # - number_of_quotas:           Number of quotas acquired.
  # - quota_value_at_application: Quota price at the time of application.
  #
  # @return [Application] A valid Application instance.
  factory :application do
    association :fund_investment

    request_date               { Date.current }
    cotization_date            { Date.current }
    liquidation_date           { Date.current }
    financial_value            { BigDecimal("50000.00") }
    number_of_quotas           { BigDecimal("500.0") }
    quota_value_at_application { BigDecimal("100.0") }
  end
end

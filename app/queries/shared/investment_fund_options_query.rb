# frozen_string_literal: true

# Builds select-field option collections for investment fund records.
#
# This query object centralizes option formatting logic used by rich select
# components across the application interface. It returns all investment funds
# ordered by CNPJ and formatted according to the UI component contract.
#
# The returned structure is compatible with Rails select helpers and custom
# rich-select components expecting:
# - display label
# - value identifier
# - metadata attributes
#
# @author Moisés Reis
module Shared
  class InvestmentFundOptionsQuery

    class << self

      # =============================================================
      #                        PUBLIC METHODS
      # =============================================================

      # Returns all investment funds formatted for select option rendering.
      #
      # Each option contains:
      # - the fund display name
      # - the investment fund identifier
      # - a subtitle metadata attribute containing the fund CNPJ
      #
      # Returned format:
      # [
      #   [
      #     "Fund Name",
      #     1,
      #     {
      #       data: {
      #         subtitle: "00.000.000/0001-00"
      #       }
      #     }
      #   ]
      # ]
      #
      # @return [Array<Array>] Collection formatted for select helpers.
      def call
        InvestmentFund
          .order(:cnpj)
          .map do |investment_fund|
            [
              investment_fund.fund_name,
              investment_fund.id,
              {
                data: {
                  subtitle: investment_fund.cnpj
                }
              }
            ]
          end
      end
    end
  end
end
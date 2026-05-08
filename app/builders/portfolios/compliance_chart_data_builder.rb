# app/builders/portfolios/compliance_chart_data_builder.rb

module Portfolios
  class ComplianceChartDataBuilder
    SERIES = {
      actual: "Alocação Atual",
      target: "Objetivo",
      max:    "Limite Máximo"
    }.freeze

    private_constant :SERIES

    # @param report [Array<Hash>]
    #
    # @return [Array<Hash>]
    #
    def self.call(report)
      SERIES.map do |key, label|
        {
          name: label,
          data: report.map do |row|
            [row[:article], row[key]]
          end
        }
      end
    end
  end
end
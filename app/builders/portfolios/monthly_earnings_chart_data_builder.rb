module Portfolios
  class MonthlyEarningsChartDataBuilder
    def self.call(data, year: Date.current.year)
      months = (1..12).map { |m| Date.new(year, m, 1) }

      months.map do |month|
        [
          month.strftime("%b/%y"),
          data[month] || 0
        ]
      end
    end
  end
end
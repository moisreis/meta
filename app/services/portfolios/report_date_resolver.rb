# Resolves the reference date for monthly portfolio PDF reports.
#
# Accepts day, month, and year as optional integer parameters and
# returns the most appropriate {Date} for report generation.
#
# Resolution rules (in priority order):
#   1. Full date  — day, month, and year provided → exact date.
#   2. Month/year — only month and year provided  → last day of that month.
#   3. Fallback   — any parameter absent or invalid → last day of current month.
#
# @example Full date
#   Portfolios::ReportDateResolver.call(day: 15, month: 3, year: 2025)
#   #=> #<Date: 2025-03-15>
#
# @example Month and year only
#   Portfolios::ReportDateResolver.call(day: nil, month: 3, year: 2025)
#   #=> #<Date: 2025-03-31>
#
# @example Fallback
#   Portfolios::ReportDateResolver.call(day: nil, month: nil, year: nil)
#   #=> #<Date: 2025-05-31>  (last day of current month)
module Portfolios
  class ReportDateResolver

    # @param day   [Integer, nil] Calendar day (1–31).
    # @param month [Integer, nil] Calendar month (1–12).
    # @param year  [Integer, nil] Four-digit calendar year.
    # @return [Date] Resolved reference date for the report.
    def self.call(day:, month:, year:)
      new(day: day, month: month, year: year).resolve
    end

    # @param day   [Integer, nil]
    # @param month [Integer, nil]
    # @param year  [Integer, nil]
    def initialize(day:, month:, year:)
      @day   = day
      @month = month
      @year  = year
    end

    # @return [Date]
    def resolve
      return fallback_date unless month_and_year_present?

      day.present? ? full_date : end_of_month_date
    end

    private

    attr_reader :day, :month, :year

    # @return [Boolean]
    def month_and_year_present?
      month.present? && year.present?
    end

    # Attempts to build an exact date from day/month/year.
    # Falls back to the last day of the month when the combination
    # is invalid (e.g. February 30th).
    #
    # @return [Date]
    def full_date
      Date.new(year, month, day)
    rescue ArgumentError
      end_of_month_date
    end

    # @return [Date] Last calendar day of the requested month.
    def end_of_month_date
      Date.new(year, month, -1)
    end

    # @return [Date] Last calendar day of the current month.
    def fallback_date
      Date.current.end_of_month
    end

  end
end

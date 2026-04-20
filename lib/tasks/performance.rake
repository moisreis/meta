# Manages the calculation of financial performance metrics for investment funds.
#
# This namespace provides tasks to trigger the performance calculation engine for
# specific dates or entire calendar months, ensuring metrics are up-to-date.
#
# TABLE OF CONTENTS:
#
# 1. Performance Calculation Tasks
#
# @author Moisés Reis

# =============================================================
#              1. PERFORMANCE CALCULATION TASKS
# =============================================================

namespace :performance do
  desc "Calculates performance for all funds for a specific date"
  task calculate: :environment do
    target_date = ENV['DATE'] ? Date.parse(ENV['DATE']) : Date.yesterday

    puts "Starting performance calculation for #{target_date}..."
    result = PerformanceCalculationJob.perform_now(target_date: target_date)

    puts "Completed!"
    puts "   Processed: #{result[:processed]}"
    puts "   Created: #{result[:created]}"
    puts "   Errors: #{result[:errors]}"
  end

  desc "Calculates performance for the entire month"
  task calculate_month: :environment do
    year = ENV['YEAR']&.to_i || Date.current.year
    month = ENV['MONTH']&.to_i || Date.current.month

    start_date = Date.new(year, month, 1)
    end_date = start_date.end_of_month

    puts "Calculating performance for #{start_date.strftime('%B/%Y')}..."

    (start_date..end_date).each do |date|
      next if date.sunday? || date.saturday?

      puts "Processing #{date}..."
      PerformanceCalculationJob.perform_now(target_date: date)
    end

    puts "Full month processed!"
  end
end

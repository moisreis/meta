# Manages the importation of fund valuation quotas from the CVM (Brazilian Securities and Exchange Commission).
#
# This namespace provides tasks to fetch and process historical quota data, allowing
# for incremental updates, specific date targeting, or full historical rebuilds.
#
# TABLE OF CONTENTS:
#
# 1. Standard Import Tasks
# 2. Historical & Specific Import Tasks
#
# @author Moisés Reis

# =============================================================
#                  1. STANDARD IMPORT TASKS
# =============================================================

namespace :fund_valuation do
  desc "Imports CVM quotas from the last months"
  task import: :environment do
    months_back = ENV['MONTHS']&.to_i || 2

    puts "Starting CVM quota import..."
    puts "Fetching the last #{months_back} months"
    puts ""

    result = FundValuationImportJob.perform_now(months_back: months_back)

    puts ""
    puts "Import completed!"
    puts "   Files processed: #{result[:files_processed]}"
    puts "   Records imported: #{result[:records_imported]}"
    puts "   Records skipped: #{result[:records_skipped]}"
    puts "   Duration: #{result[:duration_seconds]} seconds"
  end

  desc "Imports quotas for a specific date"
  task :import_date, [:date] => :environment do |t, args|
    target_date = args[:date] ? Date.parse(args[:date]) : Date.current
    months_back = ENV['MONTHS']&.to_i || 2

    puts "Starting CVM quota import..."
    puts "Target date: #{target_date.strftime('%d/%m/%Y')}"
    puts "Fetching #{months_back} months back"
    puts ""

    result = FundValuationImportJob.perform_now(
      start_date: target_date,
      months_back: months_back
    )

    puts ""
    puts "Import completed!"
    puts "   Files processed: #{result[:files_processed]}"
    puts "   Records imported: #{result[:records_imported]}"
  end

# =============================================================
#            2. HISTORICAL & SPECIFIC IMPORT TASKS
# =============================================================

  desc "Imports full history (12 months)"
  task import_full: :environment do
    puts "Starting full 12-month import..."
    puts "This may take a few minutes..."
    puts ""

    result = FundValuationImportJob.perform_now(months_back: 12)

    puts ""
    puts "Import completed!"
    puts "   Files processed: #{result[:files_processed]}"
    puts "   Records imported: #{result[:records_imported]}"
    puts "   Duration: #{result[:duration_seconds]} seconds"
  end
end

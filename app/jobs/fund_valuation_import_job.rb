# === fund_valuation_import_job
#
# @author Moisés Reis
# @added 12/27/2025
# @updated 01/07/2026 - Otimizado para baixar apenas meses recentes
# @package *Jobs*
# @description Downloads and imports daily fund quota values from CVM's open data portal
# @category *ActiveJob*
#
# frozen_string_literal: true

class FundValuationImportJob < ApplicationJob
  queue_as :default

  BASE_URL = "https://dados.cvm.gov.br/dados/FI/DOC/INF_DIARIO/DADOS"
  FILE_TEMPLATE = "inf_diario_fi_%<year>04d%<month>02d.zip"
  TMP_DIR = Rails.root.join("tmp", "cvm_funds")

  # Explanation:: Este método é o ponto de entrada do job. Agora aceita um parâmetro
  #               'months_back' para controlar quantos meses buscar (padrão: 2)
  def perform(start_date: Date.current, months_back: 12)
    job_key  = "fund_valuation_import_progress"
    progress = ->(pct, step) {
      Rails.cache.write(job_key, { percent: pct, step: step, done: pct >= 100 }, expires_in: 30.minutes)
    }

    start_time = Time.current
    Rails.logger.info("[FundValuationImportJob] Starting CVM import at #{start_time}")

    FileUtils.mkdir_p(TMP_DIR)

    progress.call(5, "Carregando fundos da base…")
    existing_cnpjs = Set.new(InvestmentFund.pluck(:cnpj).map { |c| c.gsub(/\D/, "") })

    if existing_cnpjs.empty?
      Rails.logger.warn("[FundValuationImportJob] No investment funds found. Import cancelled.")
      progress.call(100, "Nenhum fundo encontrado.")
      return
    end

    reference_date    = start_date.beginning_of_month
    cutoff_date       = start_date.beginning_of_month - months_back.months
    months_to_process = months_back
    months_done       = 0
    files_processed   = 0
    total_records     = 0
    total_skipped     = 0

    loop do
      break if reference_date < cutoff_date

      pct = 10 + ((months_done.to_f / months_to_process) * 80).round
      progress.call(pct, "Processando #{reference_date.strftime('%m/%Y')}…")

      zip_name = format(FILE_TEMPLATE, year: reference_date.year, month: reference_date.month)
      zip_path = TMP_DIR.join(zip_name)
      zip_url  = "#{BASE_URL}/#{zip_name}"

      if download_zip(zip_url, zip_path)
        result         = extract_and_import(zip_path, existing_cnpjs)
        total_records  += result[:imported]
        total_skipped  += result[:skipped]
        files_processed += 1
      end

      months_done    += 1
      reference_date  = reference_date.prev_month
    end

    progress.call(100, "Importação concluída! #{total_records} registros importados.")

    Rails.logger.info("[FundValuationImportJob] Done. Files: #{files_processed}, Records: #{total_records}")

  rescue StandardError => e
    Rails.logger.error("[FundValuationImportJob] FAILED: #{e.message}")
    Rails.cache.write("fund_valuation_import_progress",
                      { percent: 0, step: "Erro: #{e.message}", done: true },
                      expires_in: 10.minutes)
    raise

  ensure
    FileUtils.rm_rf(TMP_DIR)
  end

  private

  def download_zip(url, destination)
    require 'open-uri'

    Rails.logger.info("[FundValuationImportJob] Downloading #{url}")

    uri = URI.parse(url)
    options = {
      'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
    }

    URI.open(url, options) do |remote_file|
      File.open(destination, "wb") { |f| f.write(remote_file.read) }
    end

    Rails.logger.info("[FundValuationImportJob] ✓ Downloaded successfully")
    true

  rescue OpenURI::HTTPError => e
    status_code = e.io.status.first.to_i

    if status_code == 404
      Rails.logger.info("[FundValuationImportJob] File not found (404) - skipping")
      return false
    elsif status_code == 403
      Rails.logger.warn("[FundValuationImportJob] Access forbidden (403) - server may be blocking requests")
      return false
    else
      Rails.logger.error("[FundValuationImportJob] HTTP error #{status_code}: #{e.message}")
      raise
    end
  end

  def extract_and_import(zip_path, existing_cnpjs)
    require 'zip'

    imported_count = 0
    skipped_count = 0

    Zip::File.open(zip_path) do |zip|
      zip.each do |entry|
        next unless entry.name.end_with?(".csv")

        Rails.logger.info("[FundValuationImportJob] Processing #{entry.name}")
        csv_data = entry.get_input_stream.read
        result = import_csv(csv_data, existing_cnpjs)

        imported_count += result[:imported]
        skipped_count += result[:skipped]
      end
    end

    Rails.logger.info("[FundValuationImportJob] File stats - Imported: #{imported_count}, Skipped: #{skipped_count}")

    { imported: imported_count, skipped: skipped_count }
  end

  def import_csv(csv_content, existing_cnpjs)
    require 'csv'

    rows = []
    skipped = 0

    CSV.parse(csv_content, headers: true, col_sep: ";", encoding: "ISO-8859-1:UTF-8") do |row|
      # Normalize CNPJ (remove formatting)
      normalized_cnpj = row["CNPJ_FUNDO_CLASSE"].to_s.gsub(/\D/, "")

      # Skip if fund not in our database
      unless existing_cnpjs.include?(normalized_cnpj)
        skipped += 1
        next
      end

      # Format CNPJ to match database format (XX.XXX.XXX/XXXX-XX)
      formatted_cnpj = format_cnpj(normalized_cnpj)

      # Parse quota value
      quota_value = row["VL_QUOTA"].to_s.gsub(",", ".").to_f
      next if quota_value <= 0

      rows << {
        date: Date.parse(row["DT_COMPTC"]),
        fund_cnpj: formatted_cnpj,
        quota_value: quota_value,
        source: "CVM",
        created_at: Time.current,
        updated_at: Time.current
      }
    end

    # Deduplicate rows (CVM CSVs occasionally contain duplicate entries)
    rows = rows.uniq { |r| [r[:date], r[:fund_cnpj]] }

    # Batch insert/update
    FundValuation.upsert_all(
      rows,
      unique_by: %i[date fund_cnpj]
    ) if rows.any?

    { imported: rows.size, skipped: skipped }
  end

  def format_cnpj(digits)
    # Pad with zeros if needed
    digits = digits.rjust(14, "0")

    # Format as XX.XXX.XXX/XXXX-XX
    "#{digits[0..1]}.#{digits[2..4]}.#{digits[5..7]}/#{digits[8..11]}-#{digits[12..13]}"
  end
end
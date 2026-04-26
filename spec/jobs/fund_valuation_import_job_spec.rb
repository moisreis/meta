# Tests the FundValuationImportJob, responsible for downloading,
# parsing, and importing CVM fund valuation data.
#
# This spec validates external request handling, CSV parsing behavior,
# deduplication logic, and early-exit conditions.
#
# TABLE OF CONTENTS:
#   1.  Private Methods
#       1a. #download_zip
#       1b. #import_csv
#   2.  Public Methods
#       2a. #perform
#
# @author Moisés Reis

RSpec.describe FundValuationImportJob, type: :job do
  # =============================================================
  #                      1. PRIVATE METHODS
  # =============================================================

  # -------------------------------------------------------------
  #                       1a. #DOWNLOAD_ZIP
  # -------------------------------------------------------------

  describe "#download_zip (private)" do
    let(:job)  { described_class.new }
    let(:url)  { "https://dados.cvm.gov.br/dados/FI/DOC/INF_DIARIO/DADOS/inf_diario_fi_202501.zip" }
    let(:dest) { Tempfile.new(["test", ".zip"]).path }

    # Returns false on HTTP 404.
    #
    # @return [void]
    it "returns false on 404 without raising" do
      stub_request(:get, url).to_return(status: 404)

      expect(job.send(:download_zip, url, dest)).to be false
    end

    # Returns false on HTTP 403.
    #
    # @return [void]
    it "returns false on 403 without raising" do
      stub_request(:get, url).to_return(status: 403)

      expect(job.send(:download_zip, url, dest)).to be false
    end

    # Writes file and returns true on success.
    #
    # @return [void]
    it "writes the file and returns true on success" do
      stub_request(:get, url).to_return(
        status: 200,
        body: File.read(Rails.root.join("spec/fixtures/files/sample.zip")),
        headers: { 'Content-Type' => 'application/zip' }
      )

      result = job.send(:download_zip, url, dest)

      expect(result).to be true
      expect(File.exist?(dest)).to be true
    end
  end

  # -------------------------------------------------------------
  #                        1b. #IMPORT_CSV
  # -------------------------------------------------------------

  describe "#import_csv (private)" do
    let(:job)  { described_class.new }
    let(:fund) { create(:investment_fund) }

    # Sample CSV content using CVM format (semicolon-separated, ISO-8859-1).
    #
    # @return [String]
    let(:csv_content) do
      cnpj_raw = fund.cnpj.gsub(/\D/, "")

      <<~CSV.encode("ISO-8859-1")
        TP_FUNDO;CNPJ_FUNDO_CLASSE;DT_COMPTC;VL_TOTAL;VL_QUOTA;VL_PATRIM_LIQ;CAPTC_DIA;RESG_DIA;NR_COTST
        FI;#{cnpj_raw};2025-01-31;1000000;102,345678;1000000;0;0;100
      CSV
    end

    # Imports records for matching CNPJ.
    #
    # @return [void]
    it "imports records for known funds" do
      cnpj_set = Set.new([fund.cnpj.gsub(/\D/, "")])

      expect do
        job.send(:import_csv, csv_content, cnpj_set)
      end.to change(FundValuation, :count).by(1)
    end

    # Skips records for unknown CNPJ.
    #
    # @return [void]
    it "skips records for unknown funds" do
      cnpj_set = Set.new(["99999999999999"])

      expect do
        job.send(:import_csv, csv_content, cnpj_set)
      end.not_to change(FundValuation, :count)
    end

    # Ensures duplicate rows are not inserted.
    #
    # @return [void]
    it "deduplicates rows before inserting" do
      cnpj_set = Set.new([fund.cnpj.gsub(/\D/, "")])
      duplicate_csv = csv_content + csv_content.lines[1]

      expect do
        job.send(:import_csv, duplicate_csv, cnpj_set)
      end.to change(FundValuation, :count).by(1)
    end
  end

  # =============================================================
  #                      2. PUBLIC METHODS
  # =============================================================

  # -------------------------------------------------------------
  #                           2a. #PERFORM
  # -------------------------------------------------------------

  describe "#perform" do
    # Returns early when no funds exist.
    #
    # @return [void]
    it "returns early when no investment funds exist" do
      expect(described_class.new).not_to receive(:download_zip)

      described_class.perform_now
    end
  end
end

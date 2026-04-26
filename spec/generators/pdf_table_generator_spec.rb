# Tests the PdfTableGenerator, responsible for generating PDF documents
# with tabular data and applying presentation formatting rules.
#
# This spec validates PDF generation integrity and value formatting behavior.
#
# TABLE OF CONTENTS:
#   1.  Initialization
#   2.  Public Methods
#       2a. #generate
#   3.  Private Methods
#       3a. #format_value
#
# @author Moisés Reis

RSpec.describe PdfTableGenerator do
  # =============================================================
  #                         1. INITIALIZATION
  # =============================================================

  # Column definitions for table rendering.
  #
  # @return [Array<Hash>]
  let(:columns) do
    [
      { header: "Fundo",   key: :fund_name },
      { header: "Retorno", key: :monthly_return }
    ]
  end

  # Sample dataset for PDF generation.
  #
  # @return [Array<OpenStruct>]
  let(:data) do
    [
      OpenStruct.new(fund_name: "Fundo A", monthly_return: 2.5),
      OpenStruct.new(fund_name: "Fundo B", monthly_return: -1.0)
    ]
  end

  # Initializes generator instance.
  #
  # @return [PdfTableGenerator]
  subject(:generator) do
    described_class.new(
      title:   "Relatório de Performance",
      columns: columns,
      data:    data
    )
  end

  # =============================================================
  #                      2. PUBLIC METHODS
  # =============================================================

  # -------------------------------------------------------------
  #                         2a. #GENERATE
  # -------------------------------------------------------------

  describe "#generate" do
    # Returns valid PDF binary content.
    #
    # @return [void]
    it "returns a non-empty binary string (valid PDF bytes)" do
      result = generator.generate

      expect(result).to be_a(String)
      expect(result).not_to be_empty
      expect(result[0..3]).to eq("%PDF")
    end
  end

  # =============================================================
  #                      3. PRIVATE METHODS
  # =============================================================

  # -------------------------------------------------------------
  #                       3a. #FORMAT_VALUE
  # -------------------------------------------------------------

  describe "#format_value (private)" do
    # Formats nil values as italic placeholder.
    #
    # @return [void]
    it "formats nil as N/A in italic" do
      expect(generator.send(:format_value, nil))
        .to eq("<i>N/A</i>")
    end

    # Wraps negative numbers with red color tag.
    #
    # @return [void]
    it "wraps negative numbers in red color tag" do
      result = generator.send(:format_value, -1.5)

      expect(result).to include("<color rgb='ff0000'>")
    end

    # Formats positive numbers without color.
    #
    # @return [void]
    it "formats positive numbers without color tag" do
      result = generator.send(:format_value, 2.5)

      expect(result).not_to include("<color")
      expect(result).to eq("2.50")
    end

    # Formats Date using I18n short format.
    #
    # @return [void]
    it "formats Date using I18n short format" do
      date   = Date.new(2025, 1, 31)
      result = generator.send(:format_value, date)

      expect(result).to eq(I18n.l(date, format: :short))
    end

    # Converts true to localized string.
    #
    # @return [void]
    it "converts TrueClass to 'Sim'" do
      expect(generator.send(:format_value, true))
        .to eq("Sim")
    end

    # Converts false to localized string.
    #
    # @return [void]
    it "converts FalseClass to 'Não'" do
      expect(generator.send(:format_value, false))
        .to eq("Não")
    end
  end
end

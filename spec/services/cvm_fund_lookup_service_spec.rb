# Tests the CvmFundLookupService, responsible for retrieving and parsing
# investment fund data from the CVM website.
#
# This spec validates integration with external services (via VCR),
# error handling with stubbed responses, and internal parsing logic.
#
# TABLE OF CONTENTS:
#   1.  Public Interface
#       1a. .call (VCR Integration)
#       1b. .call (Stubbed Responses)
#   2.  Private Methods
#       2a. #parse_decimal
#
# @author Moisés Reis

RSpec.describe CvmFundLookupService do
  # =============================================================
  #                      1. PUBLIC INTERFACE
  # =============================================================

  # -------------------------------------------------------------
  #                1a. .CALL (VCR INTEGRATION)
  # -------------------------------------------------------------

  describe ".call", :vcr do
    context "with a valid CNPJ" do
      # Returns fund data from recorded CVM response.
      #
      # @return [void]
      it "returns fund data including name and fees",
         vcr: { cassette_name: "cvm/valid_fund" } do

        result = described_class.call("73.232.530/0001-08")

        expect(result[:fund_name]).to be_present
        expect(result[:administrator_name]).to be_present
      end
    end
  end

  # -------------------------------------------------------------
  #                 1b. .CALL (STUBBED RESPONSES)
  # -------------------------------------------------------------

  describe ".call (stubbed)" do
    context "when CVM returns a non-success response" do
      before do
        stub_request(:get, /cvmweb\.cvm\.gov\.br/)
          .to_return(status: 503)
      end

      # Returns empty hash on upstream failure.
      #
      # @return [void]
      it "returns an empty hash without raising" do
        result = described_class.call("00.000.000/0001-91")

        expect(result).to eq({})
      end
    end

    context "when CNPJ is not found in results" do
      before do
        stub_request(:get, /ResultBuscaParticFdo/)
          .to_return(
            status: 200,
            body: "<html><body><select id='ddlFundos'></select></body></html>"
          )
      end

      # Returns empty hash when no matching fund is found.
      #
      # @return [void]
      it "returns an empty hash" do
        result = described_class.call("00.000.000/0001-91")

        expect(result).to eq({})
      end
    end
  end

  # =============================================================
  #                      2. PRIVATE METHODS
  # =============================================================

  # -------------------------------------------------------------
  #                    2a. #PARSE_DECIMAL
  # -------------------------------------------------------------

  describe "#parse_decimal (private)" do
    let(:service) { described_class.new("73232530000108") }

    # Converts Brazilian decimal format to BigDecimal.
    #
    # @return [void]
    it "converts Brazilian decimal notation (comma) to BigDecimal" do
      result = service.send(:parse_decimal, "1,50")

      expect(result).to eq(BigDecimal("1.5"))
    end

    # Returns nil for blank input.
    #
    # @return [void]
    it "returns nil for blank input" do
      expect(service.send(:parse_decimal, "")).to be_nil
      expect(service.send(:parse_decimal, nil)).to be_nil
    end

    # Strips non-numeric characters except comma.
    #
    # @return [void]
    it "strips non-numeric characters except commas" do
      result = service.send(:parse_decimal, "0,50 % a.a.")

      expect(result).to eq(BigDecimal("0.50"))
    end
  end
end

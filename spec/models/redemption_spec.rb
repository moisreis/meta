# Tests the Redemption model, covering validations, business rules,
# and instance methods related to quota redemption logic.
#
# This spec ensures correctness of redemption constraints, validates
# allowed types, enforces quota limits, and verifies derived calculations.
#
# TABLE OF CONTENTS:
#   1.  Validations
#   2.  Custom Validations
#       2a. sufficient_quotas_available
#   3.  Instance Methods
#       3a. #effective_quota_value
#       3b. #sync_dates
#
# @author Moisés Reis

RSpec.describe Redemption, type: :model do
  # =============================================================
  #                         1. VALIDATIONS
  # =============================================================

  describe "validations" do
    # Ensures required attributes and numerical constraints.
    #
    # @return [void]
    it { is_expected.to validate_presence_of(:fund_investment_id) }
    it { is_expected.to validate_presence_of(:request_date) }
    it { is_expected.to validate_numericality_of(:redeemed_liquid_value).is_greater_than(0).allow_nil }
    it { is_expected.to validate_numericality_of(:redeemed_quotas).is_greater_than(0).allow_nil }

    # Rejects unsupported redemption types.
    #
    # @return [void]
    it "rejects an invalid redemption_type" do
      r = build(:redemption, redemption_type: "unknown")

      expect(r).not_to be_valid
    end

    # Accepts all defined redemption types.
    #
    # @return [void]
    it "accepts all valid redemption types" do
      %w[partial total emergency scheduled].each do |type|
        r = build(:redemption, redemption_type: type)

        expect(r).to be_valid, "Expected #{type} to be valid"
      end
    end
  end

  # =============================================================
  #                    2. CUSTOM VALIDATIONS
  # =============================================================

  # -------------------------------------------------------------
  #         2a. SUFFICIENT QUOTAS AVAILABLE
  # -------------------------------------------------------------

  describe "#sufficient_quotas_available" do
    # Rejects redemptions exceeding available quotas.
    #
    # @return [void]
    it "rejects redemption that exceeds total_quotas_held" do
      fi = create(:fund_investment, total_quotas_held: BigDecimal("100"))
      r  = build(:redemption,
                 fund_investment: fi,
                 redeemed_quotas: BigDecimal("101"))

      expect(r).not_to be_valid
      expect(r.errors[:redeemed_quotas]).to be_present
    end

    # Allows redemption equal to total quotas.
    #
    # @return [void]
    it "allows redemption equal to total_quotas_held" do
      fi = create(:fund_investment, total_quotas_held: BigDecimal("100"))

      r = build(:redemption,
                fund_investment:        fi,
                redeemed_quotas:        BigDecimal("100"),
                redeemed_liquid_value:  BigDecimal("10000"))

      expect(r).to be_valid
    end
  end

  # =============================================================
  #                     3. INSTANCE METHODS
  # =============================================================

  # -------------------------------------------------------------
  #              3a. #EFFECTIVE_QUOTA_VALUE
  # -------------------------------------------------------------

  describe "#effective_quota_value" do
    # Computes redeemed_liquid_value / redeemed_quotas.
    #
    # @return [void]
    it "divides redeemed_liquid_value by redeemed_quotas" do
      r = build(:redemption,
                redeemed_liquid_value: BigDecimal("10000"),
                redeemed_quotas:       BigDecimal("100"))

      expect(r.effective_quota_value).to eq(BigDecimal("100"))
    end

    # Returns nil when quotas are not provided.
    #
    # @return [void]
    it "returns nil when redeemed_quotas is nil" do
      r = build(:redemption, redeemed_quotas: nil)

      expect(r.effective_quota_value).to be_nil
    end
  end

  # -------------------------------------------------------------
  #                        3b. #SYNC_DATES
  # -------------------------------------------------------------

  describe "#sync_dates" do
    # Ensures explicitly provided request_date is preserved.
    #
    # @return [void]
    it "does not overwrite an explicitly set request_date" do
      yesterday = Date.current - 1.day

      r = build(:redemption,
                request_date:          yesterday,
                cotization_date:       Date.current,
                liquidation_date:      Date.current,
                redeemed_quotas:       BigDecimal("10"),
                redeemed_liquid_value: BigDecimal("1000"))

      r.valid?

      expect(r.request_date).to eq(yesterday)
    end
  end
end

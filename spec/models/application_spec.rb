# Tests the Application model, covering validations, custom business rules,
# callbacks, instance methods, and scopes.
#
# This spec validates financial consistency, chronological constraints,
# derived calculations, and side effects triggered by persistence events.
#
# TABLE OF CONTENTS:
#   1.  Validations
#   2.  Custom Validations
#       2a. cotization_after_request
#       2b. liquidation_after_cotization
#       2c. quota_calculation_consistency
#   3.  Instance Methods
#       3a. #sync_dates
#       3b. #available_quotas
#       3c. #fully_allocated?
#       3d. #calculated_quota_value
#   4.  Callbacks
#       4a. after_commit :recalculate_performance
#   5.  Scopes
#       5a. .pending_cotization
#       5b. .completed
#
# @author Moisés Reis

RSpec.describe Application, type: :model do
  # =============================================================
  #                         1. VALIDATIONS
  # =============================================================

  describe "validations" do
    # Provides a baseline subject for validation matchers.
    #
    # @return [Application]
    subject { build(:application) }

    it { is_expected.to validate_presence_of(:fund_investment_id) }
    it { is_expected.to validate_presence_of(:request_date) }
    it { is_expected.to validate_presence_of(:financial_value) }
    it { is_expected.to validate_numericality_of(:financial_value).is_greater_than(0) }
    it { is_expected.to validate_numericality_of(:number_of_quotas).is_greater_than(0).allow_nil }
    it { is_expected.to validate_numericality_of(:quota_value_at_application).is_greater_than(0).allow_nil }
  end

  # =============================================================
  #                    2. CUSTOM VALIDATIONS
  # =============================================================

  # -------------------------------------------------------------
  #              2a. COTIZATION AFTER REQUEST
  # -------------------------------------------------------------

  describe "cotization_after_request" do
    # Ensures cotization_date is not before request_date.
    #
    # @return [void]
    it "is invalid when cotization_date is before request_date" do
      app = build(:application,
                  request_date:    Date.current,
                  cotization_date: Date.current - 1.day)

      expect(app).not_to be_valid
      expect(app.errors[:cotization_date]).to be_present
    end

    # Allows equal dates.
    #
    # @return [void]
    it "is valid when cotization_date equals request_date" do
      app = build(:application,
                  request_date:    Date.current,
                  cotization_date: Date.current)

      expect(app).to be_valid
    end
  end

  # -------------------------------------------------------------
  #           2b. LIQUIDATION AFTER COTIZATION
  # -------------------------------------------------------------

  describe "liquidation_after_cotization" do
    # Ensures liquidation_date is not before cotization_date.
    #
    # @return [void]
    it "is invalid when liquidation_date is before cotization_date" do
      app = build(:application,
                  cotization_date:  Date.current,
                  liquidation_date: Date.current - 1.day)

      expect(app).not_to be_valid
      expect(app.errors[:liquidation_date]).to be_present
    end
  end

  # -------------------------------------------------------------
  #         2c. QUOTA CALCULATION CONSISTENCY
  # -------------------------------------------------------------

  describe "quota_calculation_consistency" do
    # Validates mismatch between financial value and quotas × quota value.
    #
    # @return [void]
    it "is invalid when financial_value diverges from quotas × quota_value beyond 0.1%" do
      app = build(:application,
                  financial_value:            BigDecimal("50000"),
                  number_of_quotas:           BigDecimal("500"),
                  quota_value_at_application: BigDecimal("200"))

      expect(app).not_to be_valid
      expect(app.errors[:base]).to include("financial value doesn't match quotas × quota value")
    end

    # Allows minor floating-point discrepancies within tolerance.
    #
    # @return [void]
    it "accepts small floating point discrepancies within 0.1% tolerance" do
      app = build(:application,
                  financial_value:            BigDecimal("50000"),
                  number_of_quotas:           BigDecimal("499.99"),
                  quota_value_at_application: BigDecimal("100.002"))

      expect(app).to be_valid
    end
  end

  # =============================================================
  #                     3. INSTANCE METHODS
  # =============================================================

  # -------------------------------------------------------------
  #                        3a. #SYNC_DATES
  # -------------------------------------------------------------

  describe "#sync_dates" do
    # Backfills request_date when absent.
    #
    # @return [void]
    it "back-fills request_date from cotization_date when blank" do
      app = build(:application, request_date: nil, cotization_date: Date.current)

      app.valid?

      expect(app.request_date).to eq(Date.current)
    end

    # Preserves explicitly provided request_date.
    #
    # @return [void]
    it "does not overwrite an explicitly set request_date" do
      yesterday = Date.current - 1.day

      app = build(:application,
                  request_date:     yesterday,
                  cotization_date:  Date.current,
                  liquidation_date: Date.current)

      app.valid?

      expect(app.request_date).to eq(yesterday)
    end
  end

  # -------------------------------------------------------------
  #                   3b. #AVAILABLE_QUOTAS
  # -------------------------------------------------------------

  describe "#available_quotas" do
    # Returns full quotas when no redemptions exist.
    #
    # @return [void]
    it "returns number_of_quotas when no redemptions allocated" do
      app = create(:application, number_of_quotas: BigDecimal("500"))

      expect(app.available_quotas).to eq(BigDecimal("500"))
    end

    # Returns zero when quotas are nil.
    #
    # @return [void]
    it "returns zero when number_of_quotas is nil" do
      app = build(:application, number_of_quotas: nil)

      expect(app.available_quotas).to eq(BigDecimal("0"))
    end
  end

  # -------------------------------------------------------------
  #                  3c. #FULLY_ALLOCATED?
  # -------------------------------------------------------------

  describe "#fully_allocated?" do
    # Returns false when quotas remain.
    #
    # @return [void]
    it "is false when quotas remain available" do
      app = create(:application, number_of_quotas: BigDecimal("100"))

      expect(app).not_to be_fully_allocated
    end
  end

  # -------------------------------------------------------------
  #               3d. #CALCULATED_QUOTA_VALUE
  # -------------------------------------------------------------

  describe "#calculated_quota_value" do
    # Calculates quotient of financial value and quotas.
    #
    # @return [void]
    it "divides financial_value by number_of_quotas" do
      app = build(:application,
                  financial_value:  BigDecimal("50000"),
                  number_of_quotas: BigDecimal("500"))

      expect(app.calculated_quota_value).to eq(BigDecimal("100"))
    end

    # Returns nil when quotas are nil.
    #
    # @return [void]
    it "returns nil when number_of_quotas is nil" do
      app = build(:application, number_of_quotas: nil)

      expect(app.calculated_quota_value).to be_nil
    end

    # Returns nil when quotas are zero.
    #
    # @return [void]
    it "returns nil when number_of_quotas is zero" do
      app = build(:application,
                  number_of_quotas: BigDecimal("0"),
                  financial_value:  BigDecimal("100"),
                  quota_value_at_application: nil)

      expect(app.calculated_quota_value).to be_nil
    end
  end

  # =============================================================
  #                         4. CALLBACKS
  # =============================================================

  # -------------------------------------------------------------
  #      4a. AFTER_COMMIT :RECALCULATE_PERFORMANCE
  # -------------------------------------------------------------

  describe "after_commit :recalculate_performance", :truncation do
    # Enqueues background job on creation.
    #
    # @return [void]
    it "enqueues RecalculatePerformanceJob on create" do
      expect { create(:application) }
        .to have_enqueued_job(RecalculatePerformanceJob)
    end

    # Removes conflicting PerformanceHistory records.
    #
    # @return [void]
    it "destroys PerformanceHistory for the affected period on create" do
      fi   = create(:fund_investment)
      date = Date.current

      ph = create(:performance_history,
                  fund_investment: fi,
                  period: date.end_of_month)

      create(:application,
             fund_investment: fi,
             cotization_date: date)

      expect(PerformanceHistory.find_by(id: ph.id)).to be_nil
    end
  end

  # =============================================================
  #                           5. SCOPES
  # =============================================================

  # -------------------------------------------------------------
  #               5a. .PENDING_COTIZATION
  # -------------------------------------------------------------

  describe "scopes" do
    describe ".pending_cotization" do
      # Returns applications without cotization_date.
      #
      # @return [void]
      it "returns applications without cotization_date" do
        pending = create(:application,
                         cotization_date: nil,
                         liquidation_date: nil,
                         request_date: Date.current)

        create(:application)

        expect(Application.pending_cotization).to include(pending)
      end
    end

    # -------------------------------------------------------------
    #                     5b. .COMPLETED
    # -------------------------------------------------------------

    describe ".completed" do
      # Returns only applications with liquidation_date present.
      #
      # @return [void]
      it "returns only applications with liquidation_date present" do
        done    = create(:application)
        pending = create(:application,
                         cotization_date: nil,
                         liquidation_date: nil,
                         request_date: Date.current)

        expect(Application.completed).to include(done)
        expect(Application.completed).not_to include(pending)
      end
    end
  end
end

# Tests the RecalculatePerformanceJob, responsible for delegating
# recalculation of performance snapshots for a specific fund investment.
#
# This spec verifies correct delegation to PerformanceCalculationJob
# and proper error handling when records are not found.
#
# TABLE OF CONTENTS:
#   1.  #perform
#       1a. Delegation
#       1b. Error Handling
#
# @author Moisés Reis

RSpec.describe RecalculatePerformanceJob, type: :job do
  # =============================================================
  #                           1. #PERFORM
  # =============================================================

  describe "#perform" do
    # -------------------------------------------------------------
    #                         1a. DELEGATION
    # -------------------------------------------------------------

    # Delegates snapshot calculation to PerformanceCalculationJob.
    #
    # @return [void]
    it "delegates to PerformanceCalculationJob#calculate_snapshot!" do
      fund      = create(:investment_fund)
      portfolio = create(:portfolio)
      fi        = create(:fund_investment, portfolio: portfolio, investment_fund: fund)

      inner_job = instance_double(PerformanceCalculationJob)

      allow(PerformanceCalculationJob).to receive(:new).and_return(inner_job)

      expect(inner_job).to receive(:send)
        .with(:calculate_snapshot!, fi, Date.new(2025, 1, 31))

      described_class.perform_now(
        fund_investment_id: fi.id,
        reference_date: "2025-01-31"
      )
    end

    # -------------------------------------------------------------
    #                      1b. ERROR HANDLING
    # -------------------------------------------------------------

    # Raises error when fund_investment does not exist.
    #
    # @raise [ActiveRecord::RecordNotFound]
    # @return [void]
    it "raises ActiveRecord::RecordNotFound for unknown fund_investment_id" do
      expect do
        described_class.perform_now(
          fund_investment_id: -1,
          reference_date: Date.current
        )
      end.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end

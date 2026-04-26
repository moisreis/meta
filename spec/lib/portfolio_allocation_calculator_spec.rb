# Tests the PortfolioAllocationCalculator service, responsible for recalculating
# percentage allocations across fund investments within a portfolio.
#
# This spec verifies proportional allocation logic, ensures totals sum correctly,
# and validates behavior under edge conditions such as zero market value.
#
# TABLE OF CONTENTS:
#   1.  .recalculate!
#       1a. Base Case — Multiple Funds
#       1b. Edge Case — Zero Market Value
#
# @author Moisés Reis

RSpec.describe PortfolioAllocationCalculator do
  # =============================================================
  #                         1. .RECALCULATE!
  # =============================================================

  describe ".recalculate!" do
    let(:portfolio) { create(:portfolio) }

    # -------------------------------------------------------------
    #               1a. BASE CASE — MULTIPLE FUNDS
    # -------------------------------------------------------------

    context "with two fund investments" do
      let!(:fi1) { create(:fund_investment, portfolio: portfolio) }
      let!(:fi2) { create(:fund_investment, portfolio: portfolio) }

      before do
        # Seed applications to simulate invested capital.
        create(:application,
               fund_investment: fi1,
               financial_value: BigDecimal("60000"),
               number_of_quotas: BigDecimal("600"),
               quota_value_at_application: BigDecimal("100"))

        create(:application,
               fund_investment: fi2,
               financial_value: BigDecimal("40000"),
               number_of_quotas: BigDecimal("400"),
               quota_value_at_application: BigDecimal("100"))

        # Stub current market values.
        allow(fi1).to receive(:current_market_value).and_return(BigDecimal("60000"))
        allow(fi2).to receive(:current_market_value).and_return(BigDecimal("40000"))

        # Stub association loading.
        allow(portfolio).to receive(:fund_investments)
          .and_return(double(includes: [fi1, fi2]))
      end

      # Ensures allocation percentages sum to 100%.
      #
      # @return [void]
      it "allocations sum to 100" do
        PortfolioAllocationCalculator.recalculate!(portfolio)

        total = portfolio.fund_investments
                         .map(&:reload)
                         .sum(&:percentage_allocation)

        expect(total).to be_within(BigDecimal("0.01")).of(BigDecimal("100"))
      end

      # Ensures proportional weights are correctly assigned.
      #
      # @return [void]
      it "assigns correct weights" do
        PortfolioAllocationCalculator.recalculate!(portfolio)

        fi1.reload
        fi2.reload

        expect(fi1.percentage_allocation)
          .to be_within(BigDecimal("0.01")).of(BigDecimal("60"))

        expect(fi2.percentage_allocation)
          .to be_within(BigDecimal("0.01")).of(BigDecimal("40"))
      end
    end

    # -------------------------------------------------------------
    #           1b. EDGE CASE — ZERO MARKET VALUE
    # -------------------------------------------------------------

    context "when total market value is zero" do
      let!(:fi) { create(:fund_investment, portfolio: portfolio) }

      # Ensures no updates occur when there is no market value.
      #
      # @return [void]
      it "returns early without updating" do
        expect(fi).not_to receive(:update_columns)

        PortfolioAllocationCalculator.recalculate!(portfolio)
      end
    end
  end
end

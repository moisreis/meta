# Tests the PerformanceCalculationJob, responsible for computing
# monthly and yearly returns and persisting performance snapshots.
#
# This spec validates financial calculations, compounding logic,
# resilience to missing data, and internal quota lookup behavior.
#
# TABLE OF CONTENTS:
#   1.  Monthly Return Calculation
#   2.  Yearly Return Calculation
#   3.  Error Resilience
#   4.  Internal Methods
#       4a. #find_quota_value
#
# @author Moisés Reis

RSpec.describe PerformanceCalculationJob, type: :job do
  # Initializes job instance.
  #
  # @return [PerformanceCalculationJob]
  let(:job) { described_class.new }

  # =============================================================
  #              1. MONTHLY RETURN CALCULATION
  # =============================================================

  describe "monthly_return calculation" do
    # Calculates return based on quota variation.
    #
    # @return [void]
    it "calculates return as quota variation percentage" do
      fund         = create(:investment_fund)
      portfolio    = create(:portfolio)
      fi           = create(:fund_investment, portfolio: portfolio, investment_fund: fund)
      period_start = Date.new(2025, 1, 1)
      period_end   = Date.new(2025, 1, 31)

      # Initial quota: 100, final quota: 105 → return = 5%
      create(:fund_valuation,
             fund_cnpj: fund.cnpj,
             date: period_start - 1.day,
             quota_value: BigDecimal("100"))

      create(:fund_valuation,
             fund_cnpj: fund.cnpj,
             date: period_end,
             quota_value: BigDecimal("105"))

      create(:application,
             fund_investment: fi,
             cotization_date: period_start,
             number_of_quotas: BigDecimal("1000"),
             financial_value: BigDecimal("100000"),
             quota_value_at_application: BigDecimal("100"))

      travel_to(Date.new(2025, 2, 1)) do
        job.perform(target_date: Date.new(2025, 2, 1))
      end

      ph = PerformanceHistory.find_by(fund_investment_id: fi.id, period: period_end)

      expect(ph).to be_present
      expect(ph.monthly_return)
        .to be_within(BigDecimal("0.01"))
        .of(BigDecimal("5.0"))
    end
  end

  # =============================================================
  #              2. YEARLY RETURN CALCULATION
  # =============================================================

  describe "yearly_return calculation" do
    # Applies geometric compounding over monthly returns.
    #
    # @return [void]
    it "compounds prior monthly returns geometrically" do
      fund      = create(:investment_fund)
      portfolio = create(:portfolio)
      fi        = create(:fund_investment, portfolio: portfolio, investment_fund: fund)

      create(:performance_history,
             fund_investment: fi,
             portfolio: portfolio,
             period: Date.new(2025, 1, 31),
             monthly_return: BigDecimal("2.0"))

      feb = create(:performance_history,
                   fund_investment: fi,
                   portfolio: portfolio,
                   period: Date.new(2025, 2, 28),
                   monthly_return: BigDecimal("2.0"))

      # (1.02 × 1.02 × 1.02 - 1) × 100 ≈ 6.1208%
      result = job.send(:calculate_yearly_return, feb, BigDecimal("2.0"))

      expect(result)
        .to be_within(BigDecimal("0.01"))
        .of(BigDecimal("6.1208"))
    end
  end

  # =============================================================
  #                    3. ERROR RESILIENCE
  # =============================================================

  describe "error resilience" do
    # Ensures job continues processing when some funds lack data.
    #
    # @return [void]
    it "skips fund_investments without quota data and processes others" do
      fund1 = create(:investment_fund)
      fund2 = create(:investment_fund)
      portfolio = create(:portfolio)

      fi1 = create(:fund_investment, portfolio: portfolio, investment_fund: fund1)
      fi2 = create(:fund_investment, portfolio: portfolio, investment_fund: fund2)

      # Only fund2 has valuation data.
      date = Date.new(2025, 1, 31)

      create(:fund_valuation,
             fund_cnpj: fund2.cnpj,
             date: date - 1.day,
             quota_value: BigDecimal("100"))

      create(:fund_valuation,
             fund_cnpj: fund2.cnpj,
             date: date,
             quota_value: BigDecimal("102"))

      create(:application,
             fund_investment: fi2,
             cotization_date: Date.new(2025, 1, 1),
             number_of_quotas: BigDecimal("100"),
             financial_value: BigDecimal("10000"),
             quota_value_at_application: BigDecimal("100"))

      expect do
        travel_to(Date.new(2025, 2, 1)) do
          job.perform(target_date: Date.new(2025, 2, 1))
        end
      end.not_to raise_error

      expect(PerformanceHistory.where(fund_investment_id: fi1.id)).to be_empty
      expect(PerformanceHistory.where(fund_investment_id: fi2.id)).not_to be_empty
    end
  end

  # =============================================================
  #                      4. INTERNAL METHODS
  # =============================================================

  # -------------------------------------------------------------
  #                  4a. #FIND_QUOTA_VALUE
  # -------------------------------------------------------------

  describe "#find_quota_value" do
    # Finds quota value within fallback window (up to 5 days).
    #
    # @return [void]
    it "returns quota value from up to 5 days before target date" do
      fund = create(:investment_fund)

      create(:fund_valuation,
             fund_cnpj: fund.cnpj,
             date: Date.new(2025, 1, 28),
             quota_value: BigDecimal("110"))

      result = job.send(:find_quota_value, fund.cnpj, Date.new(2025, 1, 31))

      expect(result).to eq(BigDecimal("110"))
    end

    # Returns nil when no valuation exists within fallback window.
    #
    # @return [void]
    it "returns nil when no valuation found within 5 days" do
      fund = create(:investment_fund)

      result = job.send(:find_quota_value, fund.cnpj, Date.new(2025, 1, 31))

      expect(result).to be_nil
    end
  end
end

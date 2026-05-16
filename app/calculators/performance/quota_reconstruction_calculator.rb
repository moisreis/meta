# frozen_string_literal: true

module Performance
  class QuotaReconstructionCalculator

    class << self
      # == call
      #
      # @author Moisés Reis
      #
      # Parameters::
      # - *fund_investment* - FundInvestment instance.
      # - *date*            - Target reconstruction date.
      #
      # Returns::
      # - Reconstructed quota balance as a BigDecimal.
      #
      def call(fund_investment:, date:)
        new(fund_investment:, date:).call
      end
    end

    # == initialize
    #
    # @author Moisés Reis
    #
    def initialize(fund_investment:, date:)
      @fund_investment = fund_investment
      @date            = date
    end

    # == call
    #
    # @author Moisés Reis
    #
    # Returns::
    # - Reconstructed quota balance as a BigDecimal.
    #
    def call
      applications_total - redemptions_total
    end

    private

    attr_reader :fund_investment, :date

    def applications_total
      BigDecimal(
        fund_investment
          .applications
          .where("cotization_date <= ?", date)
          .sum(:number_of_quotas)
          .to_s
      )
    end

    def redemptions_total
      BigDecimal(
        fund_investment
          .redemptions
          .where("cotization_date <= ?", date)
          .sum(:redeemed_quotas)
          .to_s
      )
    end

  end
end

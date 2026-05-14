# app/lib/portfolios/quota_reconstruction.rb
module Portfolios
  module QuotaReconstruction
    def reconstruct_quotas_at(fund_investment, date)
      apps = fund_investment.applications
                            .where("cotization_date <= ?", date)
                            .sum(:number_of_quotas)
      reds = fund_investment.redemptions
                            .where("cotization_date <= ?", date)
                            .sum(:redeemed_quotas)
      BigDecimal(apps.to_s) - BigDecimal(reds.to_s)
    end
  end
end

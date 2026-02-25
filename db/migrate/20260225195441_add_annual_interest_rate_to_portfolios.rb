class AddAnnualInterestRateToPortfolios < ActiveRecord::Migration[8.1]
  def change
    add_column :portfolios, :annual_interest_rate, :decimal, precision: 8, scale: 4, default: 0, null: false
  end
end

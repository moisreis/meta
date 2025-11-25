class CreateFundInvestments < ActiveRecord::Migration[8.1]
  def change
    create_table :fund_investments do |t|
      t.references :portfolio, null: false, foreign_key: true
      t.references :investment_fund, null: false, foreign_key: true
      t.decimal :total_invested_value
      t.decimal :total_quotas_held
      t.decimal :percentage_allocation

      t.timestamps
    end
  end
end

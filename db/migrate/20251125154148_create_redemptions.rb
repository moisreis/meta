class CreateRedemptions < ActiveRecord::Migration[8.1]
  def change
    create_table :redemptions do |t|
      t.references :fund_investment, null: false, foreign_key: true
      t.date :request_date
      t.date :cotization_date
      t.date :liquidation_date
      t.decimal :redeemed_liquid_value
      t.decimal :redeemed_quotas
      t.decimal :redemption_yield
      t.string :redemption_type

      t.timestamps
    end
  end
end
